#!/usr/bin/env python3
"""Unit tests for report.py transcript parsing."""
import json
import tempfile
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import report

def write_jsonl(path, lines):
    with open(path, 'w') as f:
        for l in lines:
            f.write(json.dumps(l) + '\n')

def make_transcript(skill_name=None, tools_used=None, input_tokens=1000, output_tokens=200):
    lines = []
    if skill_name:
        lines.append({"type": "assistant", "message": {
            "content": [{"type": "tool_use", "name": "Skill",
                         "input": {"skill": f"etcd-druid:{skill_name}"}}],
            "usage": {"input_tokens": input_tokens, "output_tokens": output_tokens,
                      "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}
        }})
    for t in (tools_used or []):
        lines.append({"type": "assistant", "message": {
            "content": [{"type": "tool_use", "name": t, "input": {}}],
            "usage": {"input_tokens": 0, "output_tokens": 0,
                      "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}
        }})
    return lines

def test_parse_skill_invoked():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'claude-output.json')
        write_jsonl(p, make_transcript(skill_name='plan', input_tokens=12000, output_tokens=430))
        result = report.parse_transcript(p)
        assert result['skill_invoked'] == 'plan', f"expected 'plan' got {result['skill_invoked']}"
        assert result['tokens'] == 12430
        assert result['cost_usd'] > 0

def test_parse_no_skill():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'claude-output.json')
        write_jsonl(p, make_transcript())
        result = report.parse_transcript(p)
        assert result['skill_invoked'] is None

def test_parse_tokens():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'claude-output.json')
        write_jsonl(p, make_transcript(skill_name='debug', input_tokens=5000, output_tokens=300))
        result = report.parse_transcript(p)
        assert result['tokens'] == 5300
        assert abs(result['cost_usd'] - (5000 * 3 / 1e6 + 300 * 15 / 1e6)) < 0.0001

def test_load_result_pass():
    with tempfile.TemporaryDirectory() as d:
        r = {'result': 'passed', 'failure_message': None,
             'duration_s': 14, 'suite': 'trigger', 'name': 'plan-naive'}
        with open(os.path.join(d, 'result.json'), 'w') as f:
            json.dump(r, f)
        loaded = report.load_result(d)
        assert loaded['result'] == 'passed'
        assert loaded['duration_s'] == 14

def test_load_result_missing():
    with tempfile.TemporaryDirectory() as d:
        loaded = report.load_result(d)
        assert loaded['result'] == 'other'
        assert 'result.json missing' in loaded['failure_message']

if __name__ == '__main__':
    test_parse_skill_invoked()
    test_parse_no_skill()
    test_parse_tokens()
    test_load_result_pass()
    test_load_result_missing()
    print('All tests passed.')
