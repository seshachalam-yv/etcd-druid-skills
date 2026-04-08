---
name: observations
description: Use when the session-start notification mentions pending plugin observations, or when you want to review and triage captured plugin improvement findings.
user-invocable: true
effort: low
---

# Plugin Observations Triage

Review captured observations about the etcd-druid-skills plugin and decide what to do with each one.

## How observations are captured

The Stop hook (`hooks/observe-plugin-improvement.sh`) silently evaluates each response
after it is generated. When it finds a specific, high-confidence finding that a plugin
skill, hook, or prompt is wrong or incomplete, it writes a structured entry to
`plugin-observations.md` in the plugin root.

You are never interrupted during active work — this skill is the only entry point
for reviewing and acting on those findings.

---

## Process

### Step 1: Read the observations file

```bash
cat "${CLAUDE_PLUGIN_ROOT}/plugin-observations.md"
```

If the file does not exist or has no open entries, report: "No open observations." and stop.

### Step 2: Present each open observation

For each `## OBS-NNN` entry with `**Status:** open`, present it clearly:

```
OBS-NNN — <type> in <plugin_file>
Section: <plugin_section>
Confidence: <confidence>

Wrong / Missing:
  <wrong_text>

Should be:
  <correct_text>

Evidence:
  <evidence>
```

Then ask the user:

> **What would you like to do with OBS-NNN?**
> - **R** — Raise a PR to fix this now
> - **S** — Skip for now (keep open, review again later)
> - **D** — Dismiss (not worth fixing, mark as resolved with no PR)

Wait for the user's response before moving to the next observation.

### Step 3: Act on the user's choice

**R — Raise PR:**

1. Read the referenced plugin file to confirm the issue still exists
2. If the issue no longer exists (already fixed): tell the user, mark as resolved with note "auto-resolved — already fixed"
3. If it still exists: apply the fix directly to the skill file
4. Commit: `Fix <what> in <skill-name> skill`
5. Create PR:
   ```bash
   gh pr create \
     --repo seshachalam-yv/etcd-druid-skills \
     --base master \
     --title "Fix <what> in <skill-name> skill" \
     --body "$(cat <<'EOF'
   /kind bug

   **What this PR does / why we need it:**
   <correct_text from the observation>

   **Discovered via:** Auto-captured plugin observation OBS-NNN

   **Evidence:**
   > <evidence from the observation>
   EOF
   )"
   ```
6. Mark observation as resolved in `plugin-observations.md`:
   - Change `**Status:** open` to `**Status:** resolved — PR #NNNN`

**S — Skip:**
Move to the next observation. The entry remains open.

**D — Dismiss:**
Mark observation as resolved in `plugin-observations.md`:
- Change `**Status:** open` to `**Status:** dismissed`
- Add a one-line note if the user gave a reason

### Step 4: After all observations

Report a summary:
```
Triage complete.
  Raised: N PR(s)
  Skipped: N (still open)
  Dismissed: N
```

If any were skipped, mention: "Run /etcd-druid:observations again when ready to revisit them."

---

## Rules

- Never raise a PR without user confirmation (the "R" choice is the confirmation)
- Never modify a skill file without reading it first to confirm the issue still exists
- Never batch-dismiss observations without showing them individually
- If an observation references a file that no longer exists, auto-resolve it with note "file removed"
