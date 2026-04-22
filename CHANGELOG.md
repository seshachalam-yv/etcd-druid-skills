# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-04-22

### Documentation
- *(readme)* Add Gardener-style logo with amber lightning bolt (#9) ([853d7ee](https://github.com/seshachalam-yv/etcd-druid-skills/commit/853d7eedd109c062d7b75797f79e4e782ed2fe97))
- *(readme)* Add Gardener-style logo with amber lightning bolt (#8) ([8dddd6a](https://github.com/seshachalam-yv/etcd-druid-skills/commit/8dddd6a3b3294da2a7a2d4062f0ea94f6c11e2db))
- *(readme)* Full redesign to industry-standard quality (#6) ([94996a4](https://github.com/seshachalam-yv/etcd-druid-skills/commit/94996a4e67eb6478dd045a5c4e84549810738546))
- Replace Mermaid diagrams with compact ASCII workflow art ([2297713](https://github.com/seshachalam-yv/etcd-druid-skills/commit/2297713b2c7bf7062f00bc9bbae2548466aa301a))
- Add Mermaid workflow and skill interaction diagrams to README ([4debd2f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/4debd2f2138c236209d50497beea87b951347045))
- Rewrite README to match plugin ecosystem conventions ([6676cb1](https://github.com/seshachalam-yv/etcd-druid-skills/commit/6676cb1c537a059e2c926af00f6fedc8bd8afa83))
- Add evaluation guide, test definitions, and results ([2f704fe](https://github.com/seshachalam-yv/etcd-druid-skills/commit/2f704fee709d40efce788a48398295ffd7c8a78d))


### Features
- *(skills)* Skill improvements from obs-001 through obs-006 (#4) ([1d58e74](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1d58e7499e6576c11c2a881d463c01341cc10d81))
- Improve plugin based on upstream PR evaluation ([a4c3544](https://github.com/seshachalam-yv/etcd-druid-skills/commit/a4c354483fd43215bf1aacb4da6ad1501ce505e6))


### Fixes
- Address gaps found in evaluation iteration 1 ([f32e939](https://github.com/seshachalam-yv/etcd-druid-skills/commit/f32e93973ac4dfa81cd69ed5256228d4f4499f3b))


## [0.1.1] - 2026-04-21

### CI / Infrastructure
- *(release)* Fix git-cliff tar extraction path ([feeb2ad](https://github.com/seshachalam-yv/etcd-druid-skills/commit/feeb2ad2add45f40f1c189f47dfb56f71aef2072))
- *(release)* Replace orhun/git-cliff-action with direct binary install ([4278b8c](https://github.com/seshachalam-yv/etcd-druid-skills/commit/4278b8c9763558523880af8686336f72babc762b))
- *(release)* Replace tag-push trigger with workflow_dispatch ([d654369](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d65436994839898d05fff774ce48ccc230cc248c))
- *(release)* Add PR template, issue templates, cliff.toml, and bump script ([442db4d](https://github.com/seshachalam-yv/etcd-druid-skills/commit/442db4d0ab92ff3680223848383fdd10676bcc51))


### Documentation
- Add releasing.md with step-by-step release instructions ([126bc83](https://github.com/seshachalam-yv/etcd-druid-skills/commit/126bc83049bd44a7c71fa480c2b423dbfcaff9b6))


## [0.1.0] - 2026-04-21

### CI / Infrastructure
- Add release and validate GitHub Actions workflows ([e9a2872](https://github.com/seshachalam-yv/etcd-druid-skills/commit/e9a28727854816bb9872c29a281d24f012db4f4d))


### Documentation
- *(readme)* Dissolve 'What's inside' section, promote subsections to H2 ([0f3d7ad](https://github.com/seshachalam-yv/etcd-druid-skills/commit/0f3d7ad59d8c96de2d850c9a0e38588349c32e83))
- *(readme)* Merge duplicate skills tables into one consolidated table ([c0787cb](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c0787cbbd493b14d023acd10e126371f0af57823))
- *(readme)* Move skill interaction map to follow workflow diagram ([d0d9a1a](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d0d9a1ab982e7096fab0e61c10e0c43ea96d8409))
- *(readme)* Move Philosophy section before Installation ([ed26508](https://github.com/seshachalam-yv/etcd-druid-skills/commit/ed26508393ea89ae0c4586b1e7ea6a283aac91a0))
- *(readme)* Update version references to v1.8.0 ([d18ca4b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d18ca4b71b98684ea9c5e275db8876a2a6dae8f4))
- *(readme)* Move Installation section to top ([c939c0c](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c939c0cc51331bb63a6b1e864175515b2a1de16d))
- *(receiving-review)* Fix contradictory Gate 2 reference — Gate 2 is already complete before PR opens; on approval the maintainer merges ([05b1fb9](https://github.com/seshachalam-yv/etcd-druid-skills/commit/05b1fb9cfdd34c9b79009e26894ab44646e26bcc))
- *(review)* Add Count and Apply fields to observation capture template — required by observations/SKILL.md sort and triage logic ([55afb68](https://github.com/seshachalam-yv/etcd-druid-skills/commit/55afb687c988d3cf0271cafb6189800ca6457bc0))
- *(tdd)* Add Anti-Pattern 6 — table-driven tests without t.Parallel() miss shared-state races ([117006f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/117006f2e253afc2d57d8aa11463b821997e0e0a))
- *(code-reviewer)* Add OnDemandSnapshot auto-trigger paths to EtcdOpsTask footgun check ([eee0365](https://github.com/seshachalam-yv/etcd-druid-skills/commit/eee0365d8d1f7cb00d14c160be7244c61f8d88c4))
- *(verification)* Add receiving-review to description — it invokes the verification gate but was missing from the caller list ([0505dfd](https://github.com/seshachalam-yv/etcd-druid-skills/commit/0505dfd667eecbc81d26e954e7069fc1af29e46b))
- *(plan,implement)* Fix plan→implement contract — add Fork Root field to plan template, clarify branch name is derived not extracted ([7f73376](https://github.com/seshachalam-yv/etcd-druid-skills/commit/7f733762184cbdb0a4ae4b72856af669fdf4cdea))
- *(implement)* Add Who approves line to Gate 2 matching Gate 1 symmetry ([b8a0b69](https://github.com/seshachalam-yv/etcd-druid-skills/commit/b8a0b6903851010728f8ab28ecef989200fb6f5d))
- *(implement)* Add implementer report to spec-reviewer context in Phase 2 step d ([708bccb](https://github.com/seshachalam-yv/etcd-druid-skills/commit/708bccb86fa24218d1efc2aadab57340b9e0fd4d))
- *(spec-reviewer)* Add upstream-branch safety check to Also check list ([7d74f21](https://github.com/seshachalam-yv/etcd-druid-skills/commit/7d74f217658a0a4cf679449d04884302e0c12bbb))
- Add Red Flags sections to implement and api-change skills ([9099564](https://github.com/seshachalam-yv/etcd-druid-skills/commit/9099564b5b22c213a9f9aeffa4f9ff1bb790c9c6))
- *(code-reviewer)* Sync Known Footguns with review/SKILL.md (3 missing entries) ([ae94849](https://github.com/seshachalam-yv/etcd-druid-skills/commit/ae94849970950bb08e87047cd12fd3e8faae7837))
- *(observations)* Add Iron Law — no PR without explicit user R choice ([803f83c](https://github.com/seshachalam-yv/etcd-druid-skills/commit/803f83cd3e83cf79519044af5b8ae275b5bd32e6))
- *(review)* Add conditional Handoff for standalone invocation from tdd or debug ([c24d2f3](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c24d2f38322e0d7f3b5acc7ac2ccb4bca0450731))
- *(e2e)* Add implement Phase 3 return path to Handoff section ([09aafb7](https://github.com/seshachalam-yv/etcd-druid-skills/commit/09aafb748c27d1a54b1de32423adc75ec02a4211))
- *(observations)* Add Count/Apply fields to Step 2 presentation and add Handoff section ([c56b07c](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c56b07c5878afe6492f7ff5ac60becbe02a21b32))
- *(debug)* Anchor tdd return path to Phase 5 in Handoff section ([c7bd0fe](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c7bd0fe4115c0fb878693ab4b42c2c00cad975d3))
- *(tdd)* Restore debug Phase 5 return anchor in Handoff section ([f8ffc31](https://github.com/seshachalam-yv/etcd-druid-skills/commit/f8ffc311fa4d02f24f103bf29e152f6dd3205d7f))
- Add observations skill to README skills section and usage examples ([c29811e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c29811edfb819ad1e358f5c2d765003e67d57248))
- *(readme)* Update installation instructions for marketplace-based install ([9a086f9](https://github.com/seshachalam-yv/etcd-druid-skills/commit/9a086f97059ccf97bb188790eab63d4c7caced48))


### Features
- *(implement)* Add task readiness matrix with resume backfill to Phase 2 start ([2786b8a](https://github.com/seshachalam-yv/etcd-druid-skills/commit/2786b8a8b32c1ffe69ec317b5a4e9bb36236e0c7))
- *(implement)* Make plan file checkbox write-back explicit in per-task loop step h ([e9e8cd7](https://github.com/seshachalam-yv/etcd-druid-skills/commit/e9e8cd70d30f1392bda2e46204b3d4011fb56960))
- *(implement)* Add API Delta presence check to Phase 1 setup ([02648d4](https://github.com/seshachalam-yv/etcd-druid-skills/commit/02648d4a60638bdaf476354c3f01f3219e885681))
- *(plan)* Add WHEN/THEN requirement blocks and API Delta section to plan template ([5cb1d2d](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5cb1d2db4b7570022bb29d2ec547e5c79d69fc90))
- *(api-change)* Reference API Delta plan section as source of truth in Step 1 ([c950537](https://github.com/seshachalam-yv/etcd-druid-skills/commit/c950537bbb98e44100ee9f70f1ac75de616fee9e))
- *(implement)* Add WHEN/THEN block scanning to spec-reviewer step 3 ([01d8a15](https://github.com/seshachalam-yv/etcd-druid-skills/commit/01d8a158c09fc2527ecf21ac7ee97cddec757415))


### Fixes
- *(implement)* Broaden error-handling section scope to include internal/controller/ ([9f8927f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/9f8927fa3b4060d8f7f6ca67b9788e2280f9192e))
- *(tdd)* Correct Ginkgo prohibition — partial migration, not complete ([d5d48dd](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d5d48dda4484e4f3014b6d66b82d9335b84af64f))
- *(reference)* Add Pending→Rejected direct path in EtcdOpsTask state machine ([80b6d5b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/80b6d5b2128bcd9936186f78778d4028247236dc))
- *(e2e)* Correct IMAGEVECTOR_OVERWRITE note — export and inline both work ([1d317a6](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1d317a664f4f8cbca529461b9ced02ba0bf74804))
- *(check-dev-docs)* Correct api doc path to changing-api.md ([cb57c14](https://github.com/seshachalam-yv/etcd-druid-skills/commit/cb57c14de2238d37c42b0fe5bebe2e8fc2dbe044))
- *(observe-hook)* Remove stale CORRECTION_FLAG definition at line 16 ([1672d6e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1672d6ec56df08ddcfa2e4d2e618b1f573b83f8d))
- *(observe-hook)* Write Apply field as plain value not code block — observations/SKILL.md reads it directly to run as bash command ([62fe561](https://github.com/seshachalam-yv/etcd-druid-skills/commit/62fe561f2dcbc6f6ef55a5f4a6b005f86f4ba6a1))
- *(session-start)* Add EtcdOpsTask, druidctl, feature gates to reference skill description ([b1a253b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/b1a253bf759ab90a0fb2c9439d564c0517ccef02))
- *(check-dev-docs)* Remove dead hack/* case arm — .go filter makes it unreachable ([765cd7b](https://github.com/seshachalam-yv/etcd-druid-skills/commit/765cd7b22543e2e16894e6742fbbb040b8ed6a9b))
- Move *_test.go case to top of pattern list (was shadowed by controller/component) ([cd593f6](https://github.com/seshachalam-yv/etcd-druid-skills/commit/cd593f699615a79452b2b1b46bcbe4bfb29640e1))
- Restructure session-memory.sh to emit single JSON output ([d2cf40f](https://github.com/seshachalam-yv/etcd-druid-skills/commit/d2cf40f359eaf1ed8c4253989da5ea9e7b605c66))
- Harden count-increment dedup in write_observation ([4a16460](https://github.com/seshachalam-yv/etcd-druid-skills/commit/4a16460659e038af5650b9d4e67ad2a13d6c2b58))
- Use temp file for obs_diff substitution (BSD awk compat) ([1c20650](https://github.com/seshachalam-yv/etcd-druid-skills/commit/1c206505c7b415c9568f07e76a7618dc508e9bd0))
- Prevent shell expansion of obs_diff in write_observation heredoc ([0fec5b4](https://github.com/seshachalam-yv/etcd-druid-skills/commit/0fec5b4c08438e9ead440f83b16b504a37dbd13b))
- Resolve code quality issues in write-memory.sh and observe-plugin-improvement.sh ([f9da828](https://github.com/seshachalam-yv/etcd-druid-skills/commit/f9da828a9649c0e5a51ff2ad5b8660b1425e6467))


### Miscellaneous
- *(implement)* Raise minimum model floor from haiku to sonnet ([0245840](https://github.com/seshachalam-yv/etcd-druid-skills/commit/024584089a39bd2c3b99a0f28135c7465f8d3739))
- Bump version to 1.8.0 ([5146610](https://github.com/seshachalam-yv/etcd-druid-skills/commit/5146610718e716de17b89864bd71776bf1e131a9))
- Add marketplace.json for plugin marketplace registration ([89cad4e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/89cad4ee201f3f8fa2d619a0f0795f95a914cff8))
- Bump plugin.json to v1.7.0, update description to reflect plan/implement split ([ccde73e](https://github.com/seshachalam-yv/etcd-druid-skills/commit/ccde73e282b84b5c68bbd9651e5bb7bc212df96d))


### Refactor
- *(implement)* Add conditional checklist sections to code-reviewer prompt ([6e4ddc4](https://github.com/seshachalam-yv/etcd-druid-skills/commit/6e4ddc441d52703df053bba6da26796b01acdef1))
- *(implement)* Add CONTEXT/RULES/PROCEDURE/OUTPUT headers to implementer prompt ([dc47c69](https://github.com/seshachalam-yv/etcd-druid-skills/commit/dc47c69060940d11250af5f9d996602011ac67a6))


