---
layout: default
title: etcd-druid-skills
---

<style>
  .hero { text-align: center; padding: 40px 0 20px; }
  .hero img { max-width: 480px; width: 100%; }
  .hero .tagline { color: #3a8a5c; font-size: 1.1em; margin-top: 8px; }
  .badges { text-align: center; margin: 16px 0 32px; }
  .badges img { margin: 0 4px; }
  .ecosystem { text-align: center; margin-bottom: 24px; font-size: 0.95em; }
  .ecosystem a { color: #009F76; }

  .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 20px; margin: 32px 0; }
  .feature { background: #161b22; border: 1px solid #30363d; border-radius: 10px; padding: 20px; }
  .feature h3 { color: #009F76; margin-top: 0; font-size: 1em; }
  .feature p { color: #8b949e; font-size: 0.9em; margin-bottom: 0; }

  .install-box { background: #0d1117; border: 1px solid #30363d; border-radius: 10px; padding: 24px; margin: 24px 0; }
  .install-box code { color: #79c0ff; }

  .compare-table { width: 100%; border-collapse: collapse; margin: 24px 0; font-size: 0.9em; }
  .compare-table th { background: #161b22; color: #009F76; padding: 12px; text-align: left; border-bottom: 2px solid #30363d; }
  .compare-table td { padding: 12px; border-bottom: 1px solid #21262d; vertical-align: top; }
  .compare-table td:first-child { color: #f85149; }
  .compare-table td:last-child { color: #3fb950; }

  .skills-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; margin: 20px 0; }
  .skill-card { background: #0d1117; border: 1px solid #30363d; border-radius: 8px; padding: 14px; }
  .skill-card .name { color: #009F76; font-weight: 700; font-family: monospace; font-size: 0.95em; }
  .skill-card .desc { color: #8b949e; font-size: 0.82em; margin-top: 4px; }
  .skill-card .invoke { color: #484f58; font-size: 0.78em; font-family: monospace; margin-top: 6px; }

  .section-title { border-bottom: 1px solid #30363d; padding-bottom: 8px; margin-top: 48px; }
  .iron-law { font-family: monospace; color: #f0883e; font-size: 0.85em; }

  .workflow-ascii { background: #0d1117; border: 1px solid #30363d; border-radius: 8px; padding: 20px; overflow-x: auto; font-size: 0.85em; line-height: 1.5; }

  .cta { text-align: center; margin: 48px 0 24px; }
  .cta a { display: inline-block; background: #009F76; color: white; padding: 12px 32px; border-radius: 8px; text-decoration: none; font-weight: 700; font-size: 1.05em; }
  .cta a:hover { background: #00b386; }
</style>

<div class="hero">
  <img src="docs/logo.svg" alt="etcd-druid-skills">
</div>

<div class="ecosystem">
  <strong>Ecosystem:</strong>
  <a href="https://github.com/gardener/etcd-druid">etcd-druid</a> ·
  <a href="https://github.com/gardener/etcd-backup-restore">etcd-backup-restore</a> ·
  <a href="https://github.com/gardener/etcd-wrapper">etcd-wrapper</a>
</div>

<div class="badges">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="License"></a>
  <a href=".claude-plugin/plugin.json"><img src="https://img.shields.io/badge/version-0.2.0-green.svg" alt="Version"></a>
  <a href="docs/evaluation.md"><img src="https://img.shields.io/badge/eval%20pass%20rate-96%25-brightgreen.svg" alt="Eval Pass Rate"></a>
  <a href="https://github.com/obra/superpowers"><img src="https://img.shields.io/badge/Inspired%20by-Superpowers-orange" alt="Inspired by Superpowers"></a>
</div>

A Claude Code plugin that makes your AI coding agent a capable etcd-druid contributor — not just a code writer, but a workflow-following engineer who knows the two-commit rule, picks the right test framework per repo, protects generated files, and won't push without your approval.
{: style="text-align: center; max-width: 700px; margin: 0 auto 32px; color: #c9d1d9; font-size: 1.05em; line-height: 1.6;" }

---

## Without vs. With This Plugin
{: .section-title }

<table class="compare-table">
<tr><th>Generic Claude</th><th>With etcd-druid-skills</th></tr>
<tr>
  <td>Edits <code>zz_generated_deepcopy.go</code> directly</td>
  <td><strong>Blocks</strong> edits to any <code>zz_generated_*</code> file via hook</td>
</tr>
<tr>
  <td>Uses wrong test framework for the repo</td>
  <td>Reads <code>docs/development/</code> before touching any file</td>
</tr>
<tr>
  <td>Forgets <code>make generate</code> after adding a field</td>
  <td>Follows the <strong>two-commit rule</strong>: field first, then generate</td>
</tr>
<tr>
  <td>Skips CEL validation entirely</td>
  <td>Places CEL validation with field-scoped + cross-field rules</td>
</tr>
<tr>
  <td>Opens PR without <code>release-note</code> Prow label</td>
  <td>Drafts PR body with correct Prow labels and release notes</td>
</tr>
<tr>
  <td>Jumps straight to implementation</td>
  <td>Writes plan with WHEN/THEN criteria; waits for Gate 1</td>
</tr>
</table>

---

## Quick Install
{: .section-title }

<div class="install-box">

<p><strong>3 commands:</strong></p>

{% highlight bash %}
/plugin marketplace add seshachalam-yv/etcd-druid-skills
/plugin install etcd-druid-skills@seshachalam-yv-etcd-druid-skills
/reload-plugins
{% endhighlight %}

<p><strong>Verify:</strong></p>

{% highlight text %}
/etcd-druid:reference
{% endhighlight %}

</div>

---

## Skills
{: .section-title }

<div class="skills-grid">
  <div class="skill-card">
    <div class="name">plan</div>
    <div class="desc">Issue intake → approach selection → code plan with WHEN/THEN acceptance criteria. <strong>Gate 1</strong> blocks code until you approve.</div>
    <div class="invoke">/etcd-druid:plan</div>
  </div>
  <div class="skill-card">
    <div class="name">implement</div>
    <div class="desc">Worktree → subagent loop (implementer → spec-reviewer → code-reviewer) → CI verify → PR. <strong>Gate 2</strong> blocks push.</div>
    <div class="invoke">/etcd-druid:implement</div>
  </div>
  <div class="skill-card">
    <div class="name">api-change</div>
    <div class="desc">CEL validation, kubebuilder markers, two-commit generate workflow, CRD integration tests.</div>
    <div class="invoke">/etcd-druid:api-change</div>
  </div>
  <div class="skill-card">
    <div class="name">tdd</div>
    <div class="desc">Red-Green-Refactor per repo. Go native for druid/wrapper, Ginkgo v2 for backup-restore.</div>
    <div class="invoke">/etcd-druid:tdd</div>
  </div>
  <div class="skill-card">
    <div class="name">debug</div>
    <div class="desc">6-phase root cause analysis, Delve, per-repo log analysis, build failure triage.</div>
    <div class="invoke">/etcd-druid:debug</div>
  </div>
  <div class="skill-card">
    <div class="name">review</div>
    <div class="desc">10-step checklist, 15 known footguns, Prow labels, release notes. Read-only subagent.</div>
    <div class="invoke">/etcd-druid:review</div>
  </div>
  <div class="skill-card">
    <div class="name">e2e</div>
    <div class="desc">KIND cluster setup, custom sidecar image builds, IMAGEVECTOR_OVERWRITE, pre-PR CI.</div>
    <div class="invoke">/etcd-druid:e2e</div>
  </div>
  <div class="skill-card">
    <div class="name">reference</div>
    <div class="desc">Make targets, file paths, feature gates, CLI flags, dependency management, cherry-pick.</div>
    <div class="invoke">/etcd-druid:reference</div>
  </div>
  <div class="skill-card">
    <div class="name">observations</div>
    <div class="desc">Triage plugin self-improvement findings: raise PR, skip, or dismiss.</div>
    <div class="invoke">/etcd-druid:observations</div>
  </div>
</div>

---

## Iron Laws
{: .section-title }

Every skill opens with one unconditional rule — addressing the thought pattern, not the abstract principle.

| Skill | Law |
|-------|-----|
| plan | <span class="iron-law">NO CODE BEFORE GATE 1</span> |
| implement | <span class="iron-law">NO PUSH BEFORE GATE 2</span> |
| tdd | <span class="iron-law">NO IMPLEMENTATION CODE BEFORE A FAILING TEST</span> |
| debug | <span class="iron-law">NO FIX ATTEMPT WITHOUT A REPRODUCIBLE FAILURE FIRST</span> |
| review | <span class="iron-law">NO VERDICT WITHOUT READING THE DIFF AND docs/development/ FIRST</span> |
| verification | <span class="iron-law">NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE</span> |

---

## Workflow
{: .section-title }

<div class="workflow-ascii"><pre>
 Issue / Bug Report
       │
       ▼
 ┌─────────────────────── /etcd-druid:plan ───────────────────────┐
 │  Read issue → explore upstream → design approach → write plan  │
 └────────────────────────────┬───────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  ⛔ GATE 1        │  ← you review the plan
                    └─────────┬─────────┘
                              │
 ┌────────────────────── /etcd-druid:implement ───────────────────┐
 │  1. Create worktree + verify baseline tests                    │
 │  2. Per-task: Implementer → Spec-reviewer → Code-reviewer      │
 │  3. Verify: make ci-checks && make test-unit                   │
 │  4. Final review: /etcd-druid:review (whole diff)              │
 └────────────────────────────┬───────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  ⛔ GATE 2        │  ← you review the diff
                    └─────────┬─────────┘
                              │
                         gh pr create
</pre></div>

---

## Evaluation
{: .section-title }

Tested against 5 real PR scenarios from `gardener/etcd-druid` and `gardener/etcd-backup-restore`:

| Scenario | Based on Real PR | Plugin | Baseline | Lift |
|----------|-----------------|--------|----------|------|
| API change | etcd-druid#1280 | 100% | 33% | +67pp |
| Feature dev | etcd-druid#1300 | 100% | 67% | +33pp |
| Bug fix | etcd-druid#1308 | 80% | 40% | +40pp |
| Refactoring | etcd-backup-restore#1013 | 100% | 33% | +67pp |
| Enhancement | etcd-backup-restore#1001 | 100% | 83% | +17pp |
| **Average** | | **96%** | **52%** | **+44pp** |

5 iterations, zero cross-iteration variance.

---

## The Component System
{: .section-title }

```
etcd-druid            Kubernetes operator — owns Etcd CRD, reconciles cluster resources
etcd-backup-restore   Sidecar — snapshots, restore, etcd initialization
etcd-wrapper          Sidecar — starts embedded etcd via backup-restore HTTP API
```

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Dependencies | `make tidy` | `make revendor` (vendored) | `make revendor` (vendored) |
| CI command | `make ci-checks` | `make verify` | `make check && make test` |
| Logging | logr | logrus | zap |

<div class="cta">
  <a href="https://github.com/seshachalam-yv/etcd-druid-skills">View on GitHub →</a>
</div>
