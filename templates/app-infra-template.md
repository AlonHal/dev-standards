# [App Name] — App Infra

<!--
TEMPLATE — copy this file into a new app's repo root (suggested name:
APP_INFRA.md), delete this comment block, and fill in every [bracketed]
field. This is distilled from app-infra.md (see dev-standards/reference/),
scaled down to solo-developer scope per DEVELOPMENT_ENVIRONMENT_STANDARDS.md,
and generalized so it fits a mobile app, a web app, or both — this
workspace's platform is for building simple apps reachable from a
smartphone, a PC, or a laptop, not one fixed tech stack.

This document answers "how does THIS app map onto the shared rules?" —
it sits between DEVELOPMENT_ENVIRONMENT_STANDARDS.md (workspace-wide,
one copy, applies to everything) and this app's own product plan (e.g.
DEVELOPMENT_PLAN.md — what the app actually does). Don't restate either;
reference them.
-->

Status: template — not yet instantiated for a specific app.

## 1. Relationship to dev-standards

This app follows `dev-standards/DEVELOPMENT_ENVIRONMENT_STANDARDS.md` for git workflow, CI, secrets, and AI-agent operating rules without modification, unless a deviation is explicitly noted in §9 below. Don't copy those rules here — link to them.

## 2. App Identity & Platform Target

- **Name**: [app name]
- **One-line description**: [what it does, one sentence — full feature scope belongs in this app's own product plan, not here]
- **Platform target** (check what applies):
  - [ ] Mobile (native — Flutter/Android, iOS later per the workspace's standard constraints)
  - [ ] Web (responsive — usable from a phone browser and a desktop browser)
  - [ ] Both
- **Connectivity model**:
  - [ ] Offline-first / local-only (no backend — like DailyDo)
  - [ ] Networked (calls a backend service — which one? [link to the backend's own repo/plan])

## 3. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Frontend framework | [e.g. Flutter, React, plain web] | |
| Backend framework (if networked) | [or "N/A — local-only"] | |
| Data storage | [e.g. SQLite+Drift on-device, or Postgres via the backend] | |
| Build tooling | [whatever the frontend framework needs] | |

If this app needs a language/framework not yet installed in the VM, add it to `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §9's tooling inventory rather than only noting it here.

## 4. Local Dev & Runtime Environment

- **Runs directly on the dev machine**: [e.g. Flutter SDK + emulator/device, or a Node/Vite dev server]
- **Needs Docker Compose**: [yes/no — if yes, what services, and does it reuse an existing `docker-compose.yml` from a sibling backend repo, or need its own?]
- Per `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §6: no Kubernetes, no per-PR namespaces, "staging" (if relevant) is a manual procedure, not a persistent environment — unless that's been revisited workspace-wide.

## 5. Testing Layers for This App

Fill in against the framework in `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §5 — mark each layer adopt-now / not-applicable / premature-placeholder for *this app specifically*, don't assume every layer applies:

| Layer | Status for this app |
|---|---|
| Static checks (format/lint) | [adopt now — applies to everything] |
| Unit tests | [adopt now — applies to everything] |
| Widget/component tests | [adopt now if there's a UI framework that supports it] |
| Integration tests | [only if this app has real dependencies to integrate against, e.g. a backend or a local DB] |
| Contract tests | [premature unless this app is a second party to an existing API contract] |
| End-to-end tests | [premature unless this app has a real deployed client-server path] |
| Manual/device smoke test | [required for anything touching platform channels the CI can't exercise — e.g. mobile builds blocked by the KVM constraint] |

## 6. MVP / Platform Scope

What's in v1 from an infra standpoint — distinct from the product feature scope in this app's own plan:
- [ ] Which platform(s) ship first if "Both" was checked in §2
- [ ] Whether a backend is needed for v1, or deferred
- [ ] Anything explicitly out of scope for v1 the same way `DEVELOPMENT_PLAN.md` §2 does for DailyDo

## 7. Subagents

Default: copy the standard three from `dev-standards/templates/agents/` (`implementer`, `test-writer`, `debugger`) into this app's `.claude/agents/` — same rules, no changes needed for most apps.

- [ ] Standard three copied in as-is
- [ ] App-specific subagent needed beyond the standard three? [name it and justify — most apps won't need one; see `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §3 before adding a new role]

## 8. What This App Deliberately Does Not Use

Default: inherit `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §11 wholesale (no Kubernetes, no multi-agent orchestrator, no observability stack, etc.). Only list something here if this app has a *different* reason to skip something than the workspace-wide default, or needs to flag a workspace-level item as newly relevant to it (e.g. "this app is the first one that makes contract tests non-premature, see backend's plan").

## 9. App-Specific Additions to the Safety Rules

Default: none — `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §7 applies as-is. Only add an entry here for a genuinely app-specific risk (DailyDo's own plan adds "never introduce network calls without an explicit human decision" because its whole premise is local-only — a networked app wouldn't need that rule, but might need a different one, e.g. "never touch production data from a dev session").

## 10. Decisions Needed

[Per-app open questions, same pattern as `DEVELOPMENT_PLAN.md` §9 and `DEVELOPMENT_ENVIRONMENT_STANDARDS.md` §12 — list what's genuinely undecided about this app's infra before starting its own Phase 0.]
