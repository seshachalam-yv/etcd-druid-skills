#!/usr/bin/env python3
"""
Aggregate eval run transcripts into summary.json (CTRF), HIGHLIGHTS.md, and report.xml.

Usage:
    python3 tests/report.py <run-dir>

<run-dir> is the timestamped output directory, e.g.
    /tmp/etcd-druid-skills-tests/1776830043/
It must contain subdirectories: trigger/<case>/claude-output.json
                                compliance/<scenario>/claude-output.json

Outputs written to <run-dir>/:
    summary.json   — CTRF 1.0.0
    HIGHLIGHTS.md  — human-readable markdown table
    report.xml     — JUnit XML for legacy CI
"""

import json
import sys
import os
import time
import datetime
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict

# Cost constants (Sonnet 4 rates, $/M tokens)
_INPUT_COST_PER_M  = 3.0
_OUTPUT_COST_PER_M = 15.0


def parse_transcript(jsonl_path: str) -> dict:
    """Parse a single claude-output.json JSONL file.

    Returns a dict with keys:
        skill_invoked (str|None): e.g. 'plan', 'debug', None
        tokens (int): total input+output tokens across all assistant messages
        cost_usd (float): estimated cost
        tools_used (list[str]): all tool names called (deduped, ordered)
    """
    skill_invoked = None
    total_input = total_output = 0
    tools_seen = []
    tools_set = set()

    try:
        with open(jsonl_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if data.get('type') != 'assistant':
                    continue
                msg = data.get('message', {})

                usage = msg.get('usage', {})
                total_input  += usage.get('input_tokens', 0)
                total_output += usage.get('output_tokens', 0)

                for block in msg.get('content', []):
                    if block.get('type') != 'tool_use':
                        continue
                    tool_name = block.get('name', '')
                    inp = block.get('input', {})

                    if tool_name == 'Skill' and skill_invoked is None:
                        raw = inp.get('skill', '')
                        # strip namespace prefix e.g. "etcd-druid:plan" -> "plan"
                        skill_invoked = raw.split(':')[-1] if raw else None

                    if tool_name not in tools_set:
                        tools_set.add(tool_name)
                        tools_seen.append(tool_name)

    except OSError:
        pass

    cost_usd = (total_input * _INPUT_COST_PER_M + total_output * _OUTPUT_COST_PER_M) / 1e6

    return {
        'skill_invoked': skill_invoked,
        'tokens': total_input + total_output,
        'cost_usd': cost_usd,
        'tools_used': tools_seen,
    }


def load_result(test_dir: str) -> dict:
    """Load the result.json sidecar written by a runner script.

    Returns a dict with keys: result, failure_message, duration_s, suite, name.
    If result.json is missing, returns status 'other' with a diagnostic message.
    """
    p = Path(test_dir) / 'result.json'
    if not p.exists():
        return {
            'result': 'other',
            'failure_message': f'result.json missing in {test_dir}',
            'duration_s': 0,
            'suite': Path(test_dir).parent.name,
            'name': Path(test_dir).name,
        }
    with open(p) as f:
        return json.load(f)


def collect_results(run_dir: str) -> list:
    """Walk <run_dir>/<suite>/<test>/ and return one dict per test case.

    Each dict has:
        name, suite, result, failure_message, duration_s,
        skill_invoked, tokens, cost_usd, tools_used, log_path
    """
    run_path = Path(run_dir)
    rows = []
    for suite_dir in sorted(run_path.iterdir()):
        if not suite_dir.is_dir():
            continue
        suite = suite_dir.name
        if suite not in ('trigger', 'compliance'):
            continue
        for test_dir in sorted(suite_dir.iterdir()):
            if not test_dir.is_dir():
                continue
            log = test_dir / 'claude-output.json'
            transcript = parse_transcript(str(log)) if log.exists() else {
                'skill_invoked': None, 'tokens': 0, 'cost_usd': 0.0, 'tools_used': []
            }
            result = load_result(str(test_dir))
            rows.append({
                'name':            result.get('name', test_dir.name),
                'suite':           suite,
                'result':          result.get('result', 'other'),
                'failure_message': result.get('failure_message'),
                'duration_s':      result.get('duration_s', 0),
                'skill_invoked':   transcript['skill_invoked'],
                'tokens':          transcript['tokens'],
                'cost_usd':        transcript['cost_usd'],
                'tools_used':      transcript['tools_used'],
                'log_path':        str(log) if log.exists() else None,
            })
    return rows


def emit_ctrf(results: list, out_path: str, run_dir: str = '') -> None:
    """Write CTRF 1.0.0 summary.json to out_path."""
    now_ms = int(time.time() * 1000)

    status_map = {'passed': 'passed', 'failed': 'failed',
                  'skipped': 'skipped', 'pending': 'pending', 'other': 'other'}

    summary = {
        'tests':   len(results),
        'passed':  sum(1 for r in results if r['result'] == 'passed'),
        'failed':  sum(1 for r in results if r['result'] == 'failed'),
        'skipped': sum(1 for r in results if r['result'] == 'skipped'),
        'pending': sum(1 for r in results if r['result'] == 'pending'),
        'other':   sum(1 for r in results if r['result'] not in ('passed','failed','skipped','pending')),
        'start':   now_ms - sum(r['duration_s'] for r in results) * 1000,
        'stop':    now_ms,
    }

    tests = []
    for r in results:
        entry = {
            'name':     r['name'],
            'status':   status_map.get(r['result'], 'other'),
            'duration': r['duration_s'] * 1000,
            'suite':    [r['suite']],
            'tags':     ['skill-trigger' if r['suite'] == 'trigger' else 'iron-law'],
        }
        if r['failure_message']:
            entry['message'] = r['failure_message']
        if r['skill_invoked']:
            entry['ai'] = f"skill etcd-druid:{r['skill_invoked']} invoked correctly"
        elif r['result'] == 'failed':
            entry['ai'] = 'Claude answered directly without loading skill'
        entry['extra'] = {
            k: v for k, v in {
                'skill_invoked': r['skill_invoked'],
                'cost_usd':      round(r['cost_usd'], 4),
                'tokens':        r['tokens'],
                'log_path':      r['log_path'],
            }.items() if v is not None
        }
        tests.append(entry)

    ctrf = {
        'reportFormat': 'CTRF',
        'specVersion':  '1.0.0',
        'results': {
            'tool':    {'name': 'etcd-druid-skills-eval'},
            'summary': summary,
            'tests':   tests,
        }
    }

    with open(out_path, 'w') as f:
        json.dump(ctrf, f, indent=2)


def emit_highlights(results: list, out_path: str) -> None:
    """Write HIGHLIGHTS.md — a human-readable markdown table of results."""
    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    passed = sum(1 for r in results if r['result'] == 'passed')
    total  = len(results)
    total_cost = sum(r['cost_usd'] for r in results)
    total_s    = sum(r['duration_s'] for r in results)

    lines = [
        f'## Test Run — {now}',
        '',
        f'Suite: all  │  {passed}/{total} passed  │  '
        f'total cost: ${total_cost:.2f}  │  total time: {total_s}s',
        '',
        '| Test | Result | Skill | Duration | Cost | Tokens |',
        '|------|--------|-------|----------|------|--------|',
    ]
    for r in results:
        icon   = '✅ PASS' if r['result'] == 'passed' else '❌ FAIL'
        skill  = f"etcd-druid:{r['skill_invoked']}" if r['skill_invoked'] else '(none)'
        dur    = f"{r['duration_s']}s"
        cost   = f"${r['cost_usd']:.2f}"
        tokens = f"{r['tokens']:,}"
        lines.append(f"| {r['name']} | {icon} | {skill} | {dur} | {cost} | {tokens} |")

    failures = [r for r in results if r['result'] != 'passed']
    if failures:
        lines += ['', '## Failures', '']
        for r in failures:
            lines.append(f"**{r['name']}** — {r['failure_message'] or 'assertion failed'}")
            if r['log_path']:
                lines.append(f"  Log: `{r['log_path']}`")
            lines.append('')

    with open(out_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
