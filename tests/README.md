# Skill Testing

## Philosophy

Skills are markdown documents, not code. Testing validates:
1. **Triggering** — Does the skill activate for the right user messages?
2. **Completeness** — Does every requirement have a corresponding section?
3. **Consistency** — Do cross-references between skills resolve correctly?

## Running Tests

```bash
# Run all tests
./tests/run-all.sh

# Run specific category
./tests/skill-triggering/test-plan-triggers.sh
./tests/skill-triggering/test-debug-triggers.sh
```

## Test Categories

### Skill Triggering (`tests/skill-triggering/`)
Validates that skill descriptions contain expected trigger keywords
and negative boundaries. Uses grep-based pattern matching.

### Cross-Reference Integrity (planned)
Validates that skill-to-skill references (e.g., "see skills/verification/SKILL.md")
point to files that actually exist.

### Structure Validation (planned)
Validates that all skills have required sections: frontmatter, Iron Law,
workflow, Red Flags (for user-invocable skills).
