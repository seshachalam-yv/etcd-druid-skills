# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-04-21

Initial public release of the etcd-druid-skills Claude Code plugin.

### Skills

- Add `plan` skill: phased planning workflow with Gate 1 approval ([5cf0dd6](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5cf0dd6))
- Add `implement` skill: gated implementation workflow with spec-reviewer, code-reviewer, and implementer subagents ([7549762](https://github.com/seshachalam-yv/etcd-druid-skills/commit/7549762), [22883f1](https://github.com/seshachalam-yv/etcd-druid-skills/commit/22883f1))
- Split `feature-dev` into `plan` + `implement` with full cross-reference wiring ([22883f1](https://github.com/seshachalam-yv/etcd-druid-skills/commit/22883f1))
- Add `tdd` skill: test-driven development workflow for etcd-druid ecosystem ([2a7dee9](https://github.com/seshachalam-yv/etcd-druid-skills/commit/2a7dee9))
- Add `debug` skill: systematic debugging for etcd-druid ecosystem ([7a12d2b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/7a12d2b))
- Add `review` skill: PR review workflow with upstream remote handling and test-run table ([58e6991](https://github.com/seshachalam-yv/etcd-druid-skills/commit/58e6991))
- Add `api-change` skill: CEL validation, generate workflow, CRD tests, and API Delta guidance ([cdf8316](https://github.com/seshachalam-yv/etcd-druid-skills/commit/cdf8316))
- Add `e2e` skill: KIND setup, custom image builds, sidecar overrides, pre-PR CI ([804f76a](https://github.com/seshachalam-yv/etcd-druid-skills/commit/804f76a))
- Add `reference` skill: make targets, file paths, druidctl, feature gates, CLI flags, tooling versions ([65d6582](https://github.com/seshachalam-yv/etcd-druid-skills/commit/65d6582))
- Add `receiving-review` skill: handling PR feedback with CI gate and Handoff ([7835999](https://github.com/seshachalam-yv/etcd-druid-skills/commit/7835999))
- Add `verification` skill: pre-completion verification gate ([fceda6f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/fceda6f))
- Add `observations` skill: cross-session plugin self-improvement loop ([ed2800e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/ed2800e))

### Hooks

- Add `session-start` hook: cross-session memory reader, skills orientation, upstream drift detection ([0450c67](https://github.com/seshachalam-yv/etcd-druid-skills/commit/0450c67), [359d4ec](https://github.com/seshachalam-yv/etcd-druid-skills/commit/359d4ec), [32a95df](https://github.com/seshachalam-yv/etcd-druid-skills/commit/32a95df))
- Add `session-memory` hook: cross-session memory writer wired into stop hook ([359d4ec](https://github.com/seshachalam-yv/etcd-druid-skills/commit/359d4ec))
- Add `guard-generated-files` hook: blocks manual edits to generated files ([5998615](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5998615))
- Add `detect-correction` hook: captures user corrections as plugin observations ([a511e81](https://github.com/seshachalam-yv/etcd-druid-skills/commit/a511e81))
- Add `observe-plugin-improvement` hook: structured diff proposals for plugin self-improvement ([5d09368](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5d09368))
- Add `check-dev-docs` hook: file-specific reminder to check upstream `docs/development/` ([691c80b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/691c80b))
- Wire `hooks.json`: session-memory on WorktreeCreate/PostCompact, async hooks throughout ([a4319cc](https://github.com/seshachalam-yv/etcd-druid-skills/commit/a4319cc))

### Enhancements

- Add task readiness matrix with resume backfill to implement Phase 2 ([2786b8a](https://github.com/seshachalam-yv/etcd-druid-skills/commit/2786b8a))
- Add API Delta section to plan template and implement Phase 1 setup ([5cb1d2d](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5cb1d2d), [02648d4](https://github.com/seshachalam-yv/etcd-druid-skills/commit/02648d4))
- Add WHEN/THEN requirement blocks to plan template and implement spec-reviewer ([5cb1d2d](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5cb1d2d), [01d8a15](https://github.com/seshachalam-yv/etcd-druid-skills/commit/01d8a15))
- Add CONTEXT/RULES/PROCEDURE/OUTPUT structure to implementer prompt ([dc47c69](https://github.com/seshachalam-yv/etcd-druid-skills/commit/dc47c69))
- Add conditional checklist sections to code-reviewer prompt ([6e4ddc4](https://github.com/seshachalam-yv/etcd-druid-skills/commit/6e4ddc4))
- Add Red Flags sections to implement and api-change skills ([9099564](https://github.com/seshachalam-yv/etcd-druid-skills/commit/9099564))
- Add e2e verification decision table to implement Phase 5 ([1036eb0](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1036eb0))
- Add etcd-druid testing anti-patterns reference ([fceda6f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/fceda6f))
- Add structured diff proposals to observations (OBS format v2) ([5d09368](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5d09368))
- Add count field to observations for frequency-sorted triage ([1bfb809](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1bfb809))
- Add OnDemandSnapshot auto-trigger paths to EtcdOpsTask footgun check ([0505dfd](https://github.com/seshachalam-yv/etcd-druid-skills/commit/0505dfd))
- Add Anti-Pattern 6 to tdd: table-driven tests without t.Parallel() ([117006f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/117006f))
- Raise minimum subagent model floor from haiku to sonnet ([0245840](https://github.com/seshachalam-yv/etcd-druid-skills/commit/0245840))
- Apply Karpathy observations: assumption surfacing, YAGNI enforcement, anti-bloat gates ([a12b8c6](https://github.com/seshachalam-yv/etcd-druid-skills/commit/a12b8c6))
- Merge 57-round systematic Superpowers comparison audit ([a008d2d](https://github.com/seshachalam-yv/etcd-druid-skills/commit/a008d2d))

### Fixes

- Fix tdd: correct Ginkgo prohibition — partial migration, not complete ([d5d48dd](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d5d48dd))
- Fix reference: add Pending→Rejected direct path in EtcdOpsTask state machine ([1d317a6](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1d317a6))
- Fix e2e: correct IMAGEVECTOR_OVERWRITE note ([cb57c14](https://github.com/seshachalam-yv/etcd-druid-skills/commit/cb57c14))
- Fix check-dev-docs: correct api doc path and remove dead hack/* case arm ([1672d6e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1672d6e), [765cd7b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/765cd7b))
- Fix observe-hook: remove stale CORRECTION_FLAG definition, write Apply as plain value ([1672d6e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1672d6e), [62fe561](https://github.com/seshachalam-yv/etcd-druid-skills/commit/62fe561))
- Fix session-start: add EtcdOpsTask, druidctl, feature gates to reference skill description ([803f83c](https://github.com/seshachalam-yv/etcd-druid-skills/commit/803f83c))
- Fix hooks.json wiring: session-memory on WorktreeCreate, PostCompact, async race ([a4319cc](https://github.com/seshachalam-yv/etcd-druid-skills/commit/a4319cc))
- Fix plan/implement contract: add Fork Root field, clarify branch name derivation ([7f73376](https://github.com/seshachalam-yv/etcd-druid-skills/commit/7f73376))
- Fix implement: broaden error-handling section scope to include internal/controller/ ([9f8927f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/9f8927f))
- Fix receiving-review: correct Gate 2 reference, add CI gate in Step 4 ([013366d](https://github.com/seshachalam-yv/etcd-druid-skills/commit/013366d))
- Fix api-change: document omitempty + has() interaction in CEL §3b ([1c86799](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1c86799))
- Fix verification: add check-generate command and Handoff section ([07ed7b3](https://github.com/seshachalam-yv/etcd-druid-skills/commit/07ed7b3))
- Fix five gaps in e2e Scenario B found via comparison task ([95e7b4c](https://github.com/seshachalam-yv/etcd-druid-skills/commit/95e7b4c))
- Fix session-memory: emit single JSON output ([d2cf40f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d2cf40f))
- Fix count-increment dedup in write_observation ([4a16460](https://github.com/seshachalam-yv/etcd-druid-skills/commit/4a16460))

### CI / Infrastructure

- Add validate workflow: version consistency, skill frontmatter, hook executability ([e9a2872](https://github.com/seshachalam-yv/etcd-druid-skills/commit/e9a2872))
- Add release workflow: tag-triggered GitHub Release with changelog extraction ([e9a2872](https://github.com/seshachalam-yv/etcd-druid-skills/commit/e9a2872))
- Add marketplace.json for plugin marketplace registration ([89cad4e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/89cad4e))
- Externalize generated file patterns to `generated-file-patterns.txt` data file ([5998615](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5998615))
- Add `.worktrees/` to `.gitignore` ([4cf3377](https://github.com/seshachalam-yv/etcd-druid-skills/commit/4cf3377))
