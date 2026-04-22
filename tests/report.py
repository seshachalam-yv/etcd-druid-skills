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
