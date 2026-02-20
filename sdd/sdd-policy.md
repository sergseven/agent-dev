# Specification-Driven Development (SDD) Policy

**Status:** Proposed

## Goal

Make system behavior, requirements, and decisions **durable, reviewable, and searchable** while keeping delivery management (planning/assignments/estimation) in the tool that already supports it.

This policy defines what belongs in **Specs (Git)** vs **Jira**, and the minimum rules to make it work.

---

## Systems of record (clear split)

### Specs (Git) are the source of truth for

- **Behavior** (what the system does)
- **Acceptance criteria** (how we know it’s correct)
- **API contracts** (GraphQL/MCP/REST surface that clients depend on)
- **Data model / invariants** (what must always be true)
- **Cross-repo contracts** (message formats, shared semantics, ownership boundaries)
- **Rationale** (why we made tradeoffs, alternatives considered)

Specs are changed **only** via GitHub Pull Requests.

### Jira is the source of truth for

- **Planning** (prioritization, roadmap, sprint scope)
- **Assignments** (who is doing the work)
- **Estimation** (story points, time, capacity)
- **Execution status** (To Do / In Progress / Done)
- **Dependencies** (blocked-by, relates-to)
- **Delivery reporting** (velocity, burn-up, stakeholder reporting)

Jira tickets must link to the spec(s) that define “what is being built/changed”.

---

## Mandatory rule: PR-based spec changes

- Any change to `spec/` must be done by GitHub PR.
- No direct edits on `main`.
- The PR description must state: **what changed** + **why**.

This is the minimal enforcement needed to keep specs trustworthy.

---

## What requires a spec change?

A PR must update a spec (or add a new spec) when it changes any of:

- External behavior (user-visible or consumer-visible)
- API contract (request/response shape, parameters, validation, errors)
- Permissions/authorization behavior
- Data retention / privacy behavior
- Cross-repo interaction or contract
- Non-trivial business rules (pricing, targeting rules, eligibility logic)

**Does not require a spec change** (label as `no-spec-change`):

- Refactoring with no behavioral change
- Purely internal optimizations that preserve outputs and contracts
- Comment/docs formatting fixes outside `spec/`

When in doubt: update the spec. The cost is low; the payoff is high.

---

## Where specs live (path is the identifier)

- Feature specs: `spec/features/<domain>/<short-name>.md`
- Cross-repo specs: `spec/cross-repo/<short-name>.md`
- ADRs: `spec/architecture/ADR-###-<short-name>.md` (optional numbering is fine here)

**Identifier rule:** the canonical identifier is the **repo + file path**.

---

## Jira ↔ Spec linking rules

### Required links

- Every Jira **Epic** must link to **one primary spec** (feature spec or cross-repo spec).
- Jira **Stories/Tasks** must link to the same spec and describe the slice they implement.

### What Jira tickets should contain (keep it short)

- The “why now” / business impact
- Constraints or deadlines
- Rollout expectations (if any)
- Link to spec

Jira should not be the place for detailed requirements that will rot.

---

## Roles and responsibilities

### Who can propose a spec change?

- Anyone (PM/PO, QA, stakeholder, engineer) can request it.

### Who writes the spec?

- **Default:** the implementer is the **scribe**.
- PM/PO contributes goals and acceptance criteria, but doesn’t need to author the whole document.

If non-technical contributors don’t adopt spec authoring, SDD still works as long as PM/PO participates in reviewing the behavior and acceptance criteria.

### Who approves a spec PR?

- **Engineering:** approves feasibility, architecture constraints, and technical correctness.
- **PM/PO (or delegate):** approves behavior + acceptance criteria when they change.
- **QA (recommended):** reviews acceptance criteria for testability.

Keep the approver set small and stable (CODEOWNERS + one PM/PO group).

---

## Definitions of Ready/Done (lightweight)

### Definition of Ready (DoR)

A Jira Story can be started when:

- Linked spec exists and is readable
- Acceptance criteria are explicit in the spec
- Repo ownership is clear (or cross-repo spec exists)

### Definition of Done (DoD)

A Jira Story is done when:

- Code merged
- Tests updated/added to satisfy acceptance criteria
- Spec updated in the same PR if implementation discovered changes/gaps

---

## Cross-repo work

If a feature spans multiple repos:

- Create a single cross-repo spec in the designated home repo: `spec/cross-repo/<short-name>.md`.
- List affected repos in frontmatter (e.g., `repos: [...]`).
- Keep one decision record; do not duplicate the authoritative text in every repo.
- Track implementation via Jira Stories per repo (all link back to the same cross-repo spec).

---

## Minimal adoption rollout (recommended)

1. Start with one domain: 3–5 specs + one template.
2. Enforce PR-only for `spec/` and add CODEOWNERS for review.
3. Add the “spec required when behavior changes” CI warning (block later).
4. Expand domain-by-domain; avoid a big-bang migration of all old docs.
