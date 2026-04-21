# Iteration Results Summary

## Iteration 1 — Baseline Comparison

Full with-plugin and baseline outputs are in `iteration-1/`. The grading report is in `results/grading-report.md`.

| Eval | With Plugin | Baseline | Delta |
|------|------------|----------|-------|
| 1 — API Change | 100% (6/6) | 33% (2/6) | +67pp |
| 2 — Feature Dev | 100% (6/6) | 67% (4/6) | +33pp |
| 3 — Bug Fix | 80% (4/5) | 40% (2/5) | +40pp |
| 4 — Refactor | 67% (4/6) | 33% (2/6) | +34pp |
| 5 — Enhancement | 83% (5/6) | 83% (5/6) | 0pp |

## Iteration 2 — Targeted Fixes

Re-ran Eval 4 and Eval 5 after adding `make revendor` emphasis, Ginkgo v2 callouts, and broadened plan description.

| Eval | Before Fix | After Fix |
|------|-----------|-----------|
| 4 — Refactor | 67% | **100%** (make revendor + Ginkgo v2 now mentioned) |
| 5 — Enhancement | 83% | 83% (plan still not triggered — implementation-oriented prompt) |

## Iterations 3, 4, 5 — Consistency Verification

All 5 evals run per iteration with the fixed plugin. Same prompts, same assertions.

| Eval | Iter 3 | Iter 4 | Iter 5 | Consistent? |
|------|--------|--------|--------|-------------|
| 1 — API Change | 100% | 100% | 100% | Yes |
| 2 — Feature Dev | 100% | 100% | 100% | Yes |
| 3 — Bug Fix | 80% | 80% | 80% | Yes |
| 4 — Refactor | 100% | 100% | 100% | Yes |
| 5 — Enhancement | 100% | 100% | 100% | Yes |

**Average (iter 3-5): 96%** — zero variance across iterations.

### Key improvement in iterations 3-5
- Eval 5 plan skill now triggers consistently (was FAIL in iter 1-2, PASS in iter 3-5) after broadening the plan description
- All `make revendor` and Ginkgo v2 assertions pass consistently after the iter-2 fix

### One structural gap remains
- Eval 3 assertion "Mentions integration tests in test/it/controller/etcdopstask/" consistently FAILs (80% instead of 100%). The debug skill focuses on unit-level verification. This is a known gap, not flakiness.
