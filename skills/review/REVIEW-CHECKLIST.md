# Review Checklist

Referenced by `review/SKILL.md`. Contains verdict formats, red flags, and repo differences.

---

## Red Flags — Stop Before Issuing Verdict

| Observation | What it means |
|---|---|
| Diff is >500 lines or touches >5 packages | Too large for a single review — flag this to the author before proceeding |
| API type changed but no generated files in diff | Two-commit rule violated — `cd api && make generate` was not run |
| Test file uses `import . "github.com/onsi/ginkgo/v2"` in etcd-druid | Wrong framework — etcd-druid uses `testing.T`, not Ginkgo |
| `time.Sleep()` in any test | Async anti-pattern — should use `Eventually`/`Consistently` |
| `CHANGES REQUESTED` verdict without reading `docs/development/` | Iron Law violation — read the docs first |
| New function, type, or parameter with no caller in this PR | YAGNI violation — flag it |

---

## Verdict

**LGTM** — all items pass, ready for PR.

**Changes required** — list each issue:
```
- <file>:<line>  What's wrong: ...  Should be: ...
```

If you are the author receiving this verdict, follow `skills/receiving-review/SKILL.md` to handle the feedback.

**Documentation gaps** — conventions in code not yet in docs/development/, OR mistakes found in this plugin's skills:

For gaps in **repo docs** (`docs/development/`): list them inline as before.

For gaps or mistakes in **this plugin's skills**: write each one directly to `plugin-observations.md` using the Bash tool:

```bash
PLUGIN_OBS="${CLAUDE_PLUGIN_ROOT}/plugin-observations.md"
NEXT_NUM=$(grep -oE '^## OBS-[0-9]+' "$PLUGIN_OBS" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1 || echo "0")
NEXT_NUM=$(printf '%03d' $((NEXT_NUM + 1)))

# Create file with header if needed
if [ ! -f "$PLUGIN_OBS" ]; then
  printf '# Plugin Observations\n\nAuto-captured. Run `/etcd-druid:observations` to triage.\n\n---\n\n## Resolved\n\n_(none yet)_\n' > "$PLUGIN_OBS"
fi

# Insert before Resolved section
TMPFILE=$(mktemp)
awk -v entry="
## OBS-${NEXT_NUM} — <type> in <plugin_file>

**Date:** $(date +%Y-%m-%d)
**Source:** review-skill
**Type:** <wrong_claim|missing_convention|missing_footgun|unclear_workflow|stale_path_or_flag>
**Confidence:** high
**Count:** 1
**File:** \`<skills/name/SKILL.md>\`
**Section:** <section heading>

**Wrong / Missing:**
> <exact wrong text, or MISSING>

**Proposed fix:**
<what it should say — specific enough to write without investigation>

**Apply:** MULTILINE — apply manually

**Evidence:**
> <what in the diff or docs revealed this>

**Status:** open

---
" '/^## Resolved/{print entry} {print}' "$PLUGIN_OBS" > "$TMPFILE" && mv "$TMPFILE" "$PLUGIN_OBS"
```

Fill in `<type>`, `<plugin_file>`, `<section>`, `<wrong_text>`, `<proposed_fix>`, and `<evidence>` from what you found. Run the bash block once per plugin gap found. The user will triage these via `/etcd-druid:observations`.

---

## Repo Differences

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Error wrapping | `druiderr.WrapError` | repo-specific patterns | standard wraps |
| Operator interface | Required | N/A | N/A |
| CLI framework | cobra (main), stdlib flag (druidctl) | cobra | stdlib `flag` |
| Dependency management | `make tidy` | `make revendor` (vendor/) | `make revendor` (vendor/) |
| Logging | logr (structured) | logrus (field-based) | zap (structured JSON) |
| CI pipeline | `.github/workflows/base.yaml` | `.github/workflows/build.yaml` | `.github/workflows/build.yaml` |
| Lint config | golangci-lint v2 | golangci-lint v2 | golangci-lint v2 |
| Generated files | deepcopy, CRDs, client/, api-ref | none | none |
| Commit convention | imperative, `(#NNNN)` suffix | imperative, `(#NNNN)` suffix | imperative, `(#NNNN)` suffix |
