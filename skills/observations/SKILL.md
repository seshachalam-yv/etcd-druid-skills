---
name: observations
description: Use when the session-start notification mentions pending plugin observations, or when you want to review and triage captured plugin improvement findings.
user-invocable: true
effort: low
---

# Plugin Observations Triage

Review captured plugin improvement observations and decide what to do with each one.
Observations come from three sources: explicit `<plugin-gap>` markers Claude emits,
user correction detection, and review-skill gap capture.

---

## Step 1: Read and pre-verify all open observations

```bash
PLUGIN_OBS="${CLAUDE_PLUGIN_ROOT}/plugin-observations.md"
cat "$PLUGIN_OBS"
```

Sort observations by **Count** (descending) before presenting — highest-frequency gaps first.
To find counts: `grep -A1 "Status.*open" "$PLUGIN_OBS" | grep "Count"`.

If the file does not exist or has no `**Status:** open` entries: report "No open observations." and stop.

Before showing any observation to the user, **verify it against the actual plugin file**:

For each open `OBS-NNN` entry:

1. Read `plugin_file` from the entry (the `**File:**` field)
2. Read the actual file: `cat "${CLAUDE_PLUGIN_ROOT}/<plugin_file>"`
3. Check whether `wrong_text` (the `**Wrong / Missing:**` field) is still present in the file
   - If `wrong_text` is `MISSING` — check whether the missing content now exists
   - If `wrong_text` is a quoted string — check whether that exact text (or close equivalent) appears in the file

**Auto-resolve** without showing the user if:
- The referenced plugin file no longer exists
- `wrong_text` is not found in the file (already fixed, or evaluator hallucinated the reference)

Mark auto-resolved entries:
```
**Status:** auto-resolved — wrong_text not found in current file
```

---

## Step 2: Present each verified open observation

For each observation that survived pre-verification, show it clearly:

```
─────────────────────────────────────────
OBS-NNN | <type> | <confidence> confidence | source: <source>
File: <plugin_file> § <plugin_section>

CURRENT FILE CONTENT at that section:
  <paste the relevant 3-5 lines from the actual file>

Wrong / Missing:
  <wrong_text>

Proposed fix:
  <correct_text>

Evidence that revealed this:
  "<evidence>"
─────────────────────────────────────────
```

Including the **current file content** is critical — it lets the user verify
whether the proposed fix is actually correct before deciding.

Then ask:

> **OBS-NNN: what would you like to do?**
> - **R** — Apply fix and raise a PR
> - **S** — Skip for now (keep open)
> - **D** — Dismiss (not worth fixing)

Wait for the user's response before moving to the next observation.

---

## Step 3: Act on the user's choice

### R — Apply fix and raise PR

1. Read the full plugin file again (fresh read)
2. Check the `**Apply:**` field in the observation:
   - If it shows a `sed` command: run it directly in the plugin root
   - If it shows `MULTILINE — apply manually`: use the Edit tool with `correct_text`
   - Always verify the result by reading the changed section back
3. Verify the edit looks correct (read the changed section back)
4. Commit:
   ```bash
   git -C "${CLAUDE_PLUGIN_ROOT}" add <plugin_file>
   git -C "${CLAUDE_PLUGIN_ROOT}" commit -m "Fix <what> in <skill-name> (OBS-NNN)"
   ```
5. Push and create PR:
   ```bash
   git -C "${CLAUDE_PLUGIN_ROOT}" push origin master
   gh pr create \
     --repo seshachalam-yv/etcd-druid-skills \
     --base master \
     --title "Fix <what> in <skill-name> skill" \
     --body "$(cat <<'EOF'
   /kind bug

   **What this PR does / why we need it:**
   <correct_text from the observation>

   **Discovered via:** Plugin observation OBS-NNN (source: <source>)

   **Evidence:**
   > <evidence from the observation>
   EOF
   )"
   ```
6. Mark resolved in `plugin-observations.md`:
   Change `**Status:** open` → `**Status:** resolved — <PR URL>`

### S — Skip

Leave status as `open`. Move to next observation.

### D — Dismiss

Change `**Status:** open` → `**Status:** dismissed`

If the user gives a reason, add: `**Dismiss reason:** <reason>`

---

## Step 4: Summary after all observations

```
Triage complete.
  Auto-resolved (already fixed): N
  Fixed and PR raised: N
  Skipped (still open): N
  Dismissed: N
```

If any were skipped: "Run /etcd-druid:observations again when ready."

---

## Rules

- Never raise a PR without the user's explicit **R** choice
- Never apply a fix without reading the current file content first
- Never batch-dismiss — show each observation individually
- The `correct_text` field is a **proposed fix**, not ground truth — verify it matches the current file before applying
- If an observation's `wrong_text` is not found in the file, auto-resolve it — do not show to user
