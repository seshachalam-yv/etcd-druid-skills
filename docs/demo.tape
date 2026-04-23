# etcd-druid-skills demo
Output docs/demo.gif

Set Shell "bash"
Set FontFamily "SF Mono"
Set FontSize 15
Set Width 1200
Set Height 600
Set Padding 20
Set Theme { "name": "etcd-druid", "black": "#0d1117", "red": "#f85149", "green": "#3fb950", "yellow": "#d29922", "blue": "#58a6ff", "magenta": "#bc8cff", "cyan": "#39d353", "white": "#c9d1d9", "brightBlack": "#484f58", "brightRed": "#ff7b72", "brightGreen": "#56d364", "brightYellow": "#e3b341", "brightBlue": "#79c0ff", "brightMagenta": "#d2a8ff", "brightCyan": "#56d364", "brightWhite": "#f0f6fc", "background": "#0d1117", "foreground": "#c9d1d9", "selection": "#264f78", "cursor": "#c9d1d9" }
Set TypingSpeed 40ms
Set CursorBlink false

# Title
Type "# etcd-druid-skills — Agentic development workflow"
Enter
Sleep 1s
Type ""
Enter

# Step 1: Show plugin install
Type "# Step 1: Install the plugin"
Enter
Sleep 500ms
Type "/plugin marketplace add seshachalam-yv/etcd-druid-skills"
Enter
Sleep 2s
Type "/plugin install etcd-druid-skills@seshachalam-yv-etcd-druid-skills"
Enter
Sleep 2s
Type "/reload-plugins"
Enter
Sleep 1.5s
Type ""
Enter

# Step 2: Reference lookup
Type "# Step 2: Quick reference — how to add an API field"
Enter
Sleep 500ms
Type "/etcd-druid:reference how to add an API field"
Enter
Sleep 4s
Type ""
Enter

# Simulated reference output
Type "echo '──────────────────────────────────────────────────────'"
Enter
Sleep 300ms
Type "echo '📋 API Field Addition — Quick Reference'"
Enter
Sleep 300ms
Type "echo '──────────────────────────────────────────────────────'"
Enter
Sleep 300ms
Type "echo ''"
Enter
Type "echo '1. Add field to api/core/v1alpha1/types_etcd.go'"
Enter
Sleep 200ms
Type "echo '2. Add CEL validation in api/core/v1alpha1/etcd_validation.go'"
Enter
Sleep 200ms
Type "echo '3. Commit #1: field + validation'"
Enter
Sleep 200ms
Type "echo '4. Run: make generate'"
Enter
Sleep 200ms
Type "echo '5. Commit #2: generated files only'"
Enter
Sleep 200ms
Type "echo '6. Run: make ci-checks && make test-unit'"
Enter
Sleep 200ms
Type "echo ''"
Enter
Type "echo '⚠️  Two-commit rule: NEVER mix hand-written and generated code'"
Enter
Sleep 2s
Type ""
Enter

# Step 3: Plan a real task
Type "# Step 3: Plan from a real GitHub issue"
Enter
Sleep 500ms
Type "/etcd-druid:plan https://github.com/gardener/etcd-druid/issues/1230"
Enter
Sleep 3s
Type ""
Enter

# Simulated plan output
Type "echo '──────────────────────────────────────────────────────'"
Enter
Sleep 300ms
Type "echo '📝 Plan — Issue #1230'"
Enter
Sleep 300ms
Type "echo '──────────────────────────────────────────────────────'"
Enter
Sleep 300ms
Type "echo ''"
Enter
Type "echo 'Analyzing issue...'"
Enter
Sleep 1s
Type "echo 'Researching related PRs and commit history...'"
Enter
Sleep 1s
Type "echo 'Reading docs/development/ contribution guide...'"
Enter
Sleep 1s
Type "echo ''"
Enter
Type "echo 'Approach: 2 options identified'"
Enter
Sleep 500ms
Type "echo '  A) Direct controller modification (3 files, 2 tests)'"
Enter
Sleep 300ms
Type "echo '  B) New reconciler with feature gate (5 files, 4 tests) ← recommended'"
Enter
Sleep 1s
Type "echo ''"
Enter
Type "echo 'Tasks:'"
Enter
Sleep 300ms
Type "echo '  [ ] Task 1: Add feature gate constant'"
Enter
Sleep 200ms
Type "echo '  [ ] Task 2: Write failing test (TDD)'"
Enter
Sleep 200ms
Type "echo '  [ ] Task 3: Implement reconciler logic'"
Enter
Sleep 200ms
Type "echo '  [ ] Task 4: Add e2e test for KIND cluster'"
Enter
Sleep 200ms
Type "echo '  [ ] Task 5: Update docs and WHEN/THEN criteria'"
Enter
Sleep 1s
Type "echo ''"
Enter
Type "echo '⛔ GATE 1 — Review the plan. Type approved to proceed.'"
Enter
Sleep 3s

# Show the gate approval
Type ""
Enter
Type "echo 'approved'"
Enter
Sleep 1s
Type "echo ''"
Enter
Type "echo '✅ Gate 1 approved — starting implementation in isolated worktree...'"
Enter
Sleep 2s

Type ""
Enter
Type "echo '🚀 etcd-druid-skills: Plan → Gate 1 → Implement → Gate 2 → PR'"
Enter
Sleep 3s
