# Development Environment Standards — SmartphonePracticingApps

Status: Phase 0–2 complete for DailyDo (repo live, hooks/tooling wired, CI running, branch protection on). `dev-standards` still needs its own Phase 1/2 (Phase 3+ pick up from there). See §10 for the live checklist.

## 1. Purpose & Scope

This document governs **process and tooling** across every component in the SmartphonePracticingApps workspace — DailyDo, the upcoming backend service, and any future app in the family. It complements, rather than replaces, each component's own plan (e.g. `DailyDo/DEVELOPMENT_PLAN.md`, and a future `BACKEND_DEVELOPMENT_PLAN.md`): those documents describe *what* each component does; this one describes *how* anything gets built, tested, and merged, and *what tooling* a fresh dev environment needs.

It exists because of `app-infra.md` (now kept at `reference/app-infra.md` for provenance) — a pasted-in write-up describing a full multi-tenant "AI software delivery platform" (control plane, multi-agent orchestrator, Kubernetes, GitHub App, Temporal, observability stack). That is explicitly **not** the target here. This document adopts the *rigor* app-infra.md describes — real git discipline, CI, layered testing, environment separation, AI-agent safety rules — scaled down to one developer working with Claude Code inside a single VM. §11 lists exactly what was left out and why.

Distilled from it, `templates/app-infra-template.md` is the **per-app companion** to this document: where this file is workspace-wide and applies to every component unchanged, that template gets copied into each new app's own repo and filled in to answer "how does *this specific* app — mobile, web, or both — map onto these shared rules?" (platform target, tech stack, which testing layers actually apply, local dev environment). It sits between this document and an app's own product plan (e.g. `DailyDo/DEVELOPMENT_PLAN.md`, which covers what the app does, not how it's built).

## 2. Workspace & Repo Strategy

**Multi-repo, one git repository per deployable component, as sibling folders under a plain (non-git) workspace root.**

```
/home/kali/Projects/SmartphonePracticingApps/     # plain directory, not a git repo
├── dev-standards/                                  # this repo — rules + shared templates
│   ├── DEVELOPMENT_ENVIRONMENT_STANDARDS.md
│   ├── reference/
│   │   └── app-infra.md                              # original source write-up, kept for provenance
│   └── templates/
│       ├── app-infra-template.md                     # per-app infra template, distilled from app-infra.md
│       ├── agents/                                    # implementer, test-writer, debugger
│       └── ...                                        # gitignores, pre-commit config, CI workflow, CLAUDE.md
├── DailyDo/                                        # its own git repo (Phase 0 git init done)
│   └── DEVELOPMENT_PLAN.md
├── backend/                                        # future, own git repo, name TBD
└── <future-app>/                                   # future, own git repo — copies templates/app-infra-template.md in
```

**Why multi-repo, not a monorepo:** DailyDo (Flutter/Android, store-released) and the future backend (continuously deployed, language TBD) already have divergent toolchains, dependency managers, and release cadences. A monorepo would need path-filtered CI and workspace tooling (Nx/Turborepo/Bazel-class) to avoid running the whole pipeline on every commit — infrastructure with no current payoff. This mirrors the principle already stated in `DEVELOPMENT_PLAN.md` §8: don't build shared machinery before a second consumer actually needs it.

**Why not git submodules either:** submodule ergonomics are a known solo-dev tax (detached-HEAD confusion, easy-to-forget `--recurse-submodules`) with little payoff at 2-3 repos. Skipped.

The tradeoff worth naming: some config duplication (`.gitignore`, pre-commit config, CI workflow) across repos. Mitigated by treating the files under `dev-standards/templates/` as **copied starting points**, not shared machinery pulled in at build time.

Each component repo gets its own `CLAUDE.md` (built from `templates/CLAUDE.md.template`) that links back to this document — that's how Claude Code actually discovers these rules automatically in every session, rather than relying on them being re-pasted into context.

## 3. Git Workflow Rules

- **Branching**: trunk-based. `main` is the only long-lived branch. No direct commits to `main` except trivial doc typos — everything else goes through a branch.
- **Commit format**: [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`, `ci:`) across all repos, including DailyDo. This is additive to `DEVELOPMENT_PLAN.md` §10, which only specified the branch model, not commit format.
- **AI-authored commit provenance**: every commit produced through a Claude Code session gets a `Co-Authored-By: Claude Code <noreply@anthropic.com>` trailer. This *is* the audit trail (`git log --grep`/`--author`) — no separate event-log system needed. Directly answers app-infra.md's "every AI change has provenance" boundary, at solo scale.
- **Worktree isolation**: for any non-trivial Claude Code task, work in a dedicated git worktree (`.worktrees/<task-slug>/`, gitignored via the shared template) on a branch named `feat|fix|chore/<task-slug>`. This isolates the agent's working directory from whatever the human has open, and keeps each task's diff independently reviewable. It's the practical, single-agent version of app-infra.md's "isolated worktrees for parallel agents." Trivial one-line changes don't need this — don't ritualize it.
- **Review (DailyDo — live as of Phase 2)**: `main` is now branch-protected server-side — a PR is required (0 approvals needed, solo dev, no one else to approve), the `check` CI run must pass, and force-pushes/deletions on `main` are blocked. `enforce_admins` is deliberately `false`: the repo owner *can* still bypass in a genuine emergency, but that's an escape hatch, not a standing practice. The flow: push a branch, `gh pr create`, wait for CI, `gh pr merge`. Verified end-to-end on DailyDo PR #1.
  - **`dev-standards` is not protected yet** — no Makefile/CI wired into it (out of Phase 2's scope, same as Phase 1 only wiring pre-commit into DailyDo). Docs there still land via direct commits to `main` for now.
- **Merge method**: both **squash** and **rebase** merges are enabled on both repos; plain merge commits are disabled repo-wide (`allow_merge_commit: false`) — this was an explicit ask, not just the earlier squash-only default. For a single-commit branch (the norm here) they produce an identical result; squash remains the practical default, rebase is there for a branch with multiple commits worth preserving individually. Both auto-delete the branch on merge.
  - **Local-only merging** (`git merge --ff-only` after keeping a branch to one commit) was the Phase 0/1 bridge workaround for landing changes on DailyDo's `main` before real PRs existed — server-side branch protection now makes direct pushes to DailyDo's `main` impossible anyway (PR required), so that workaround is moot there going forward; a real PR is now the only path in. It's still the right pattern for `dev-standards`, which has no protection yet.
  - **Before opening a PR**: run the full local suite (`make check && make test && make build`) and confirm it's green first — don't lean on CI to discover a failure that was catchable for free locally.

**Role mapping**, adapted from app-infra.md's agent-permission table and collapsed to solo scale — the clearest artifact of what was deliberately *not* rebuilt as a multi-agent orchestrator:

| app-infra.md role | Solo-scale equivalent |
|---|---|
| Planner | Human + Claude Code in plan mode |
| Implementer | Claude Code, in a worktree, with edit tools |
| Test agent | Claude Code writes tests, but a real test runner — not the agent's say-so — determines pass/fail |
| Reviewer | The human, always. A review skill may assist but never substitutes for sign-off |
| Debugger | Claude Code, same worktree, reading real failing output |
| Deployment agent | N/A yet — no deploy target beyond local Docker Compose |
| Security agent | Automated tools (secret scan, dependency audit) in pre-commit/CI, not agent judgment |

**Concrete subagents**: Implementer, Test agent, and Debugger are realized as actual Claude Code custom subagents — `.claude/agents/{implementer,test-writer,debugger}.md` — with scoped tool access and the rules above written into their system prompts. Source templates live in `dev-standards/templates/agents/`; each component repo copies them into its own `.claude/agents/`. Planner is Claude Code's built-in plan mode (no custom file needed); Reviewer and Security agent are covered by the existing `code-review` and `security-review` skills, not separate subagent files; Deployment agent has no realization yet (§6).

## 4. CI Pipeline Stages

CI is a thin wrapper around local scripts (`Makefile` targets: `check`, `test`, `build`) so there is zero drift between "what I ran by hand" and "what CI runs," and the same targets work whether or not a remote exists.

- **Now (no remote needed)**: a `Makefile` (or `scripts/ci-local.sh`) per repo. Fast checks (format, lint, secret scan) wired into a `pre-commit` hook; the full suite runs manually or via a `pre-push` hook that blocks on failure.
- **Later, if a GitHub remote is chosen**: `.github/workflows/ci.yml` (see `templates/ci-workflow.yml`) calls the exact same Makefile targets — no logic duplicated in YAML.

**DailyDo stages** (extends, doesn't replace, `DEVELOPMENT_PLAN.md` §7's validation script):
1. `dart format --output=none --set-exit-if-changed .`
2. `flutter analyze`
3. Secret scan (gitleaks) over the diff
4. `flutter test` (unit + widget, with coverage)
5. `flutter build apk --debug` (compile-check only)
6. Manual device/emulator smoke pass — **explicitly not automated**, given the KVM constraint (§9)
7. Human review + merge

Not applicable to DailyDo: integration env, contract tests, deploy preview, e2e — there's no server to integrate against and no environment to deploy. Stated plainly rather than left implicit.

**Future backend stages** (language TBD): lint/format → secret scan → unit tests → `docker compose build` → integration tests against a Compose-launched disposable dependency → human review + merge. No deploy-preview stage exists since there's no cloud target yet — "deploy" means `docker compose up` locally. Contract tests and e2e are listed in §5 but marked premature placeholders.

**"AI review" stage**: a review/security-review skill can run as a self-check before requesting human approval, but is never a stand-in for it — this is the same rule as "failing tests can't be bypassed by the agent that wrote the code" (§7), applied to review.

## 5. Testing Layers

**DailyDo**: not redefined here — `DEVELOPMENT_PLAN.md` §7 already specifies unit / widget / manual-device tests. This document only adds *process timing* (pre-commit, pre-push, CI) on top of that existing spec.

**Future backend**, with explicit premature-vs-real flags so nothing gets built before it's needed:

| Layer | Status |
|---|---|
| Unit tests | Adopt immediately once backend code exists |
| Integration tests (via `docker-compose.test.yml`, real throwaway DB) | Adopt immediately |
| Security/dependency scans (audit + secret scan) | Adopt immediately — language-agnostic enough to set up before the language is even chosen |
| Smoke test (`docker compose up` + healthcheck) | Adopt once the backend has any HTTP endpoint |
| **Contract tests** | **Premature — placeholder only.** No second service exists to hold a contract against. Trigger: DailyDo (or another app) starts calling this backend over a defined API, or ≥2 backend services talk to each other. |
| **End-to-end tests** | **Premature — placeholder only.** No deployed client-server integration exists yet. Trigger: a real client (e.g. DailyDo's eventual sync feature) actually calls the backend. |
| Mutation testing / coverage thresholds | Not adopted now — disproportionate tooling overhead at solo scale. Revisit only if silent logic regressions become a recurring, observed problem. |

## 6. Docker Compose Environments

Scaling app-infra.md's `development / preview / staging / production` ladder down to what Compose alone can express:

- One `docker-compose.yml` per backend repo (lives with that repo, not shared across the workspace), defining that service's own dependencies.
- `docker-compose.override.yml` — gitignored, machine-local dev convenience (exposed ports, hot-reload volumes).
- `docker-compose.test.yml` — tracked, used by the CI integration-test stage: spins up a disposable DB, runs migrations, runs the suite, `docker compose down -v` after.
- **"Staging" is a procedure, not a persistent environment**: build the real image, run it via `docker compose up` with prod-like config, smoke-test by hand. Stated explicitly so it doesn't read as an oversight.
- **Production is out of scope** until an actual deploy target (VPS, cloud host — undecided) exists.
- **No per-PR Kubernetes namespaces** — deferred per the earlier decision. Trigger to revisit: enough concurrently-running services that one `docker-compose.yml` can't reasonably model them, or a real multi-user hosted deployment needing autoscaling/self-healing.
- A **workspace-level** `docker-compose.yml` unioning DailyDo-adjacent backend services (for testing a sync feature against a local backend) is deferred to Phase 4 (§10) — not needed until both a backend and a consuming feature exist.

## 7. AI-Agent Operating Rules (Claude Code)

Direct adaptation of app-infra.md's safety-boundary list to solo scale:

| app-infra.md boundary | Solo-scale rule |
|---|---|
| Prod credentials never exposed to agents | No prod environment exists yet. Standing policy: Claude Code sessions only ever see dev/dummy values in `.env`, never real third-party keys |
| Agents run in isolated sandboxes | No process sandbox exists; git worktrees isolate *changes*, and destructive host commands always require explicit per-instance human confirmation — no blanket auto-approval |
| PRs required for protected branches | No direct commits to `main`; branch/worktree always required, whether or not a real PR object exists |
| Deployment manifests validated | N/A — no manifests yet; revisit once a real deploy target exists |
| Secrets injected at runtime, never committed | `.env` + `.gitignore` + gitleaks (§8) |
| Network access default-deny/allowlisted | N/A at solo scale, no job sandbox exists; substitute: CI/build steps shouldn't reach out to unknown endpoints beyond package registries |
| Destructive ops need explicit approval | Force-push, `git reset --hard`, DB drops, deleting worktrees always require explicit human confirmation, every time |
| Every AI change has provenance | Git history + `Co-Authored-By: Claude Code` trailer (§3) — sufficient, no separate audit system |
| Failing tests can't be bypassed by the agent that wrote the code | Hard rule: Claude Code never edits a test to make it pass without explicit human sign-off that the *test* was wrong; no `--no-verify` or hook-skipping |

Two DailyDo-specific additions, even though they're really product rules from `DEVELOPMENT_PLAN.md`:
- Claude Code must never introduce network calls or telemetry into DailyDo without a separate, explicit human decision — the easiest way an agent could accidentally violate the local-only requirement is via a convenience analytics SDK.
- Large multi-file refactors or deletions default to plan-mode confirmation first.

## 8. Secrets Management

**Now**: `.env` per repo (gitignored) + `.env.example` committed with placeholder keys. `gitleaks` runs as both a pre-commit hook and a CI step, scanning for accidentally committed secrets.

- DailyDo currently has zero secrets (no server, no API keys) — the `.gitignore`/gitleaks pattern is still wired in now so it's a non-event once reminders/notifications eventually need a key.
- Backend: `.env` holds DB credentials, any third-party keys (TBD), signing secrets — dev-only dummy values, loaded via Compose's `env_file:`.

**Documented upgrade path (not built now)**: move to a real secrets manager (self-hosted Vault, or the eventual host's native manager) the day there's an actual deployment holding real user data or real third-party credentials. Before that day, `.env` + gitignore is correctly scaled, not a shortcut.

## 9. Tooling Inventory

| Tool | Status | Purpose |
|---|---|---|
| `git`, `gh`, `docker`, `docker compose`, `sqlite3` | Already installed | core VCS + container + DB tooling |
| `pre-commit` | **Installed** — in an isolated venv (`~/.venvs/dev-tools`), not system-wide/apt, per the user's preference to keep local installs from interfering with anything else on the box | uniform format/lint/secret-scan hooks, driven by the shared template |
| `gitleaks` | **Installed** locally — prebuilt binary (v8.30.1) dropped into `~/.venvs/dev-tools/bin`, not apt (avoids needing a Go toolchain the golang-based pre-commit hook variant would otherwise require). **In CI**, the same binary/version is installed fresh per run (`templates/ci-workflow.yml`'s "Install gitleaks" step, via `$GITHUB_PATH`) — the local venv path doesn't exist on a GitHub runner, so this isn't optional. `make check` calls `gitleaks detect --no-git`, not `protect --staged` — staged-diff scanning is meaningless against a clean CI checkout with nothing staged | secret scanning, pre-commit + CI |
| `flutter`/`dart`, Android SDK, `adb`, emulator image | Missing — this is DailyDo's own outstanding Phase 0 item | DailyDo build/test/analyze |
| `/dev/kvm` | Missing on this box | blocks the Android emulator until fixed at the host/hypervisor level — carried forward as an unresolved risk, out of scope for this document to fix |
| `make` | Already present | the "same commands locally and in CI" mechanism — chosen over Just/Task specifically because it needs zero install |
| Backend language/runtime | **Open decision** (§12) — Node and Python are already on this box; Go is not | don't assume; flagged the same way `DEVELOPMENT_PLAN.md` §9 flags open product decisions |

`pre-commit` and `gitleaks` are both reached via `~/.venvs/dev-tools/bin` added to `PATH` in `~/.zshrc`. Nothing was installed with `sudo` or touched system Python/apt packages.

One-line note: this VM identifies as **Kali Rolling**, not Ubuntu as the earlier environment-setup summary assumed. Kali is Debian-based, so `apt` commands mostly transfer, but package availability/repos can differ — not a blocker, just worth knowing.

## 10. Phased Rollout

Same checkbox/phase-gate style as `DEVELOPMENT_PLAN.md` §6, for consistency across the document family.

**Phase 0 — Workspace foundation**
- [x] Create `dev-standards/` repo (`git init` here), commit this document + templates
- [x] `git init` in `DailyDo/` (branch renamed to `main`), add the Flutter `.gitignore` from `templates/gitignore.flutter`, first commit
- [x] Relocate `app-infra.md` into `dev-standards/reference/`; distill it into `templates/app-infra-template.md` (§12)
- [x] GitHub remote: yes, public. `DailyDo` → https://github.com/AlonHal/DailyDo, `dev-standards` → https://github.com/AlonHal/dev-standards, both pushed. Branch protection on `main` is still Phase 2 (needs a real CI check to require first).

**Phase 1 — Local process discipline (no CI infra needed yet)**
- [x] Install `pre-commit`, `gitleaks` (isolated venv, §9); wire the shared `.pre-commit-config.yaml` into DailyDo — hooks verified on a real commit + push
- [x] Adopt worktree convention, branch naming, commit convention — enforced, not just documented: `no-commit-to-branch` blocks direct `main` commits, `scripts/check-branch-name.sh` validates `<type>/<slug>`, `scripts/check-commit-msg.sh` validates Conventional Commits. Demonstrated end-to-end in DailyDo via a real worktree → branch → commit → fast-forward-merge cycle.
- [x] Add DailyDo `Makefile`/`scripts/ci-local.sh` formalizing `DEVELOPMENT_PLAN.md` §7's validation script — `make check`/`test`/`build`, Flutter checks no-op gracefully until the SDK is installed
- [x] Install subagent definitions (`implementer`, `test-writer`, `debugger`) from `templates/agents/` into DailyDo's `.claude/agents/`

**Phase 2 — Automated CI**
- [x] `.github/workflows/ci.yml` added to DailyDo, calling the same Makefile targets — [PR #1](https://github.com/AlonHal/DailyDo/pull/1), squash-merged after CI passed for real (first attempt actually failed: gitleaks wasn't installed on the runner and `protect --staged` doesn't make sense against a clean checkout — both fixed, see §9)
- [x] Branch protection on DailyDo's `main`: PR required (0 approvals, solo dev), `check` CI run required, no force-push/deletion, `enforce_admins: false` (owner escape hatch, not standing practice)
- [x] Merge policy on both repos: squash + rebase enabled, plain merge commits disabled, auto-delete branch on merge (explicit ask, not just the earlier default)
- [ ] Same CI + branch protection for `dev-standards` — not done, no Makefile/checks exist there yet to require

**Phase 3 — Backend bootstrap** (once backend product features are decided — separate effort)
- [ ] Write `BACKEND_DEVELOPMENT_PLAN.md` using `DEVELOPMENT_PLAN.md`'s phased-plan pattern as the template
- [ ] `git init` new backend repo as a sibling under the workspace root; apply `dev-standards` templates
- [ ] Add `docker-compose.yml` + `docker-compose.test.yml`, wire integration tests

**Phase 4 — Cross-component integration** (only once backend + a real consuming feature exist)
- [ ] Contract tests between DailyDo (or a web client) and backend
- [ ] E2E test driving the real client→backend path via Compose
- [ ] Workspace-level `docker-compose.yml` unioning services for full-stack local testing

**Phase 5 — Revisit heavier infra** (trigger-based, not scheduled — see §11 for exact triggers)
- [ ] Kubernetes, durable workflow engine, observability stack, secrets manager — only when their specific trigger fires

## 11. Deliberately Not Adopted Now

| app-infra.md component | Why not now | Future trigger |
|---|---|---|
| Multi-tenant control plane / customer-facing web app | Single-user solo project | Only if this becomes a product other people use |
| GitHub App / multi-provider Git abstraction | Only one remote (GitHub) is even being considered, and that's undecided | Supporting a team or multiple git providers |
| Multi-specialized-agent orchestrator | Claude Code already plays all these roles interactively, human-in-the-loop | Needing fully unattended, no-human-present agent runs across many repos |
| Kubernetes / per-PR namespaces | Single VM with existing KVM contention; Compose covers current scale | Running enough concurrent services that Compose can't model them, or real multi-user autoscaling need |
| Temporal-style durable workflow engine | No long-running/retryable pipeline steps yet | CI/deploy steps become long-running and need durable retry that a script/Actions run can't handle |
| OpenTelemetry / Prometheus / Grafana | No continuously-running deployed service to observe | Backend deployed somewhere persistent and reachable by real users |
| Vault / cloud secrets manager | No real production secrets exist | A real production deployment holding real user data or credentials |
| Contract testing framework | No second service to hold a contract against | DailyDo (or another app) defines a real API contract with the backend |
| Full e2e pipeline stage | No deployed client-server integration | Backend has a real API and a real consumer |
| Helm / Kustomize | No Kubernetes target | Same trigger as Kubernetes |

## 12. Decisions Needed

- [ ] Backend language/runtime (Node and Python are already on this box; no framework chosen)
- [x] ~~Whether a GitHub (or other) remote is wanted at all, and if so public/private~~ — resolved: GitHub, public, personal account (AlonHal)
- [ ] Backend repo naming (app-specific, e.g. `dailydo-backend`, vs. a family-level name if it's meant to serve multiple future apps)
- [x] ~~Whether to relocate `app-infra.md` out of `DailyDo/` into `dev-standards/reference/`, or leave it in place~~ — resolved: relocated, and distilled into `templates/app-infra-template.md`
- [x] ~~Merge strategy confirmation~~ — resolved: squash-merge is the target (automatic once Phase 2's real PRs exist); locally in the meantime, keep task branches to a single commit and fast-forward-merge (§3)
- [ ] KVM/nested-virtualization fix for the Android emulator — host-level, outside this document's scope, but blocks DailyDo's own Phase 0 regardless

---

**Next step**: Phase 3 — backend bootstrap (§10), once backend product features are decided; or retroactively give `dev-standards` its own Phase 1/2.
