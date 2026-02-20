---
name: reverse-spec
version: 1.0.0
status: published
description: Onboards an existing repository into the Specification-Driven Development (SDD) workflow by analysing its code and external knowledge sources in bounded-context chunks, then generating a full spec/ directory that is precise enough to reimplement the system from scratch; resumable after interruption.
authors:
  - name: agent-dev team
created: 2026-02-20
last-updated: 2026-02-20
# model: not set — inherits the session model.
# Rationale: orchestration + chunk analysis + spec synthesis require strong
# reasoning. Use whatever model the user started the session with.
sub-skills:
  - skills/external-research/SKILL.md
  - skills/spec-verify/SKILL.md
prompt-templates:
  - skills/reverse-spec/prompts/chunk-analysis.md
  - skills/reverse-spec/prompts/synthesize-spec.md
sdd-reference: sdd/spec-driven-development-workflow.md
---

# Reverse-Spec Skill

Generates a complete `spec/` directory for an existing repository following the
SDD format defined in `sdd/spec-driven-development-workflow.md`. Works in six
phases, writes progress to a state file, and can resume from any phase if
interrupted.

---

## When to Use This Skill

- Onboarding a repository that has no `spec/` directory.
- Auditing an existing `spec/` directory for coverage gaps.
- Capturing tribal knowledge before a major refactor or team handover.

---

## Prerequisites

- The target repository is accessible (local checkout or readable via tools).
- At least one of: Atlassian MCP, GitHub MCP is available (for external
  research). The skill proceeds without them but marks all found behaviour as
  tribal knowledge.
- The SDD spec template format is defined in
  `sdd/spec-driven-development-workflow.md` §Spec Template.

---

## State File

All progress is persisted in `{repo_path}/spec/.reverse-spec-state.json`.

```json
{
  "run_id": "{uuid}",
  "status": "in_progress | completed | needs_work",
  "repo_type": "{one of the six types}",
  "product_name": "{string}",
  "started_at": "{ISO timestamp}",
  "last_updated": "{ISO timestamp}",
  "current_phase": 0,
  "external_research_done": false,
  "chunks": {
    "pending": ["domain-a", "domain-b"],
    "in_progress": [],
    "completed": ["domain-z"]
  },
  "generated_specs": [
    {"domain": "domain-z", "path": "spec/features/domain-z/overview.md"}
  ],
  "verify_result": null
}

On each invocation: read this file first. If it exists and `status` is
`in_progress`, resume from `current_phase` with `chunks.pending`. If `status`
is `completed` or `needs_work`, report and ask user how to proceed.

---

## Phase 0 — Discovery & Repo Typing

### 0a. Check for existing state

If `spec/.reverse-spec-state.json` exists → resume from recorded phase (skip
to the appropriate phase below).

### 0b. Prompt user for repository type

**Always ask** — do not auto-detect.

```
Which repository type best describes this codebase?

  1. Protocol definitions   (Thrift, Protobuf — pure API contracts)
  2. Backend only           (service/application, any language)
  3. API-heavy backend      (GraphQL + REST; also covers MCP tool servers)
  4. Web frontend SPA       (single React/Vue/Angular app)
  5. Web frontend monorepo  (multiple packages/apps in one repo)
  6. ETL / data pipeline    (Airflow, Prefect, dbt, Argo Workflows, etc.)

Enter a number:
```

Record the choice as `repo_type`.

### 0c. Domain decomposition

Identify the bounded contexts that will become spec chunks. Use the
**wiring/config files first** approach — these are language-agnostic:

| Repo type | Primary decomposition signal | Fallback |
|-----------|------------------------------|----------|
| Protocol defs | One chunk per `.proto` / `.thrift` service namespace | Directory structure |
| Backend only | Top-level module/package directories under source root | Maven modules / Go modules / Python packages |
| API-heavy backend | REST route group files + GraphQL type group files + MCP tool group files | Same as backend |
| Frontend SPA | Top-level route config → route groups → page clusters | Directory structure under `src/pages/` or `src/views/` |
| Frontend monorepo | One chunk per `packages/*/` or `apps/*/` directory | `package.json` `name` fields |
| ETL | One chunk per DAG file / flow file / pipeline definition | Directory structure under `dags/`, `flows/`, `pipelines/` |

**Existing spec content:** scan `spec/` for already-present files. For any
domain that already has a spec with `status: published` or `status: committed`,
skip it and note it in the state file. Ask the user whether to refresh stale
specs (`status: draft`).

### 0d. Initialise state file

Write `spec/.reverse-spec-state.json` with all pending chunks, `current_phase: 1`.

---

## Phase 1 — Entrypoint Inventory

For each chunk, detect public entrypoints using **config and wiring files first**
(language-agnostic), then source code patterns:

### Config / wiring signals (all languages)

| Signal | Where to look |
|--------|---------------|
| HTTP routes | `openapi.yaml` / `swagger.yaml`, route registration files, framework router configs |
| Async consumers | `asyncapi.yaml`, message broker configs, consumer group config, `docker-compose` service definitions |
| Scheduled jobs | Cron expressions in config files, scheduler registration files, Helm `CronJob` specs |
| gRPC / Thrift services | `.proto` / `.thrift` files (definitive — no source scan needed) |
| ETL DAGs | DAG/flow definition files directly |
| CLI entrypoints | `pyproject.toml [scripts]`, `package.json scripts`, `Makefile` targets, `go build` main packages |

### Source code signals (language-agnostic patterns)

Scan for files whose names or directory positions suggest boundary roles:
`controller`, `handler`, `router`, `listener`, `consumer`, `subscriber`,
`resolver`, `mutation`, `query`, `tool`, `operator`, `sensor`, `task`,
`job`, `dag`, `flow`, `pipeline`.

**Do not scan all source files.** Limit to files matching the above naming
patterns within the domain's directory scope.

Write the entrypoint list into `spec/.reverse-spec-state.json` under
`chunks[domain].entrypoints`.

---

## Phase 2 — External Research

Invoke the `external-research` sub-skill once for all domains:

```
Run: skills/external-research/SKILL.md
Inputs:
  repo_path: {repo_path}
  product_name: {product_name}
  domains: {all chunk names}
  jira_project_key: {ask user, or skip}
  confluence_space_key: {ask user, or skip}
  github_dependency_repos: {ask user, or derive from imports}
```

Wait for `spec/.external-research-findings.md` to exist before continuing.
Mark `external_research_done: true` in state file.

---

## Phase 3 — Chunk Analysis Loop (resumable)

For each chunk in `chunks.pending` (in order):

### 3a. Read source files for this chunk

Using `read_file` and `grep_search`:
- Read the entrypoint files identified in Phase 1.
- Read the service/domain/use-case layer files (one directory level below
  entrypoints — this is where business rules live).
- Read test files for the domain (test names are the most honest documentation
  of intent).
- Read relevant config sections (feature flags, database schema, queue names).

Limit: read at most **30 files per chunk**. If more exist, prioritise:
entrypoints → tests → service/domain layer → everything else.

### 3b. Run chunk analysis

Apply `prompts/chunk-analysis.md` to the collected source content +
the domain's section from `spec/.external-research-findings.md`.

Extract:
- All **public behaviours** (what the system does, in business language)
- All **API surfaces** (endpoint paths, method names, tool names, event topics)
- **Data entities** and relationships used by this domain
- **Business rules** and constraints (validation, guards, state transitions,
  pricing logic, permission checks)
- **Branch/conditional logic** that implies a behaviour variant the spec must
  cover — for each `if/else`, `switch`, exception throw in service-layer code,
  record the decision criterion
- **Error scenarios** (what triggers each error path)
- **NFR signals**: SLO hints, retry config, auth references, observability calls
- **Unanswered "why" questions**: intent that cannot be inferred from code alone

### 3c. Synthesize spec file

Apply `prompts/synthesize-spec.md` to the extracted data. Produce a Markdown
file conforming exactly to the SDD spec template:

```
spec/features/{domain}/overview.md        ← for behaviour specs
spec/api/{name}.md                        ← for API contracts (API-heavy repos)
spec/architecture/ADR-{N}-{name}.md       ← for design decisions that warrant ADR form
```

YAML frontmatter must include:
```yaml
status: draft
created: {today YYYY-MM-DD}
last-updated: {today YYYY-MM-DD}
generated-by: reverse-spec v1.0.0
# jira-epic: filled only if found in external research
```

Mark any unanswered question as an explicit open item in the spec:
```markdown
> ⚠️ **Open question**: [question text]. Source code shows X happens but no
> external record explains why. Requires domain expert review.
```

### 3d. Update state file

Move chunk from `pending` to `completed`. Record generated spec path. Update
`last_updated` timestamp.

---

## Phase 4 — Architecture Synthesis

After all chunks are complete, produce three architecture-level documents:

### `spec/architecture/system-overview.md`

Cross-chunk synthesis:
- What does this system do (one paragraph for a PM, one for an engineer)?
- Component diagram (Mermaid) showing domains and their relationships.
- Technology stack (inferred from dependency files: `pom.xml`, `pyproject.toml`,
  `go.mod`, `package.json`, etc.).
- Deployment model (inferred from `Dockerfile`, `helm/`, `docker-compose.yml`).
- External dependencies (other services, databases, message brokers).

### `spec/architecture/non-functional.md`

NFR synthesis from config files and cross-cutting code patterns:
- SLOs / latency budgets (from Helm resource limits, APM config, SLO files)
- Scalability model (horizontal/vertical, stateless/stateful)
- Security posture (auth framework, TLS config, secret management)
- Observability (logging framework, metrics, tracing)
- Resilience (retry policies, circuit breakers, dead-letter queues)

Flag any NFR that **cannot be inferred** as an explicit open question.

### `spec/architecture/cross-cutting-concerns.md`

Patterns that apply across all features:
- Error handling strategy
- Correlation/trace ID propagation
- Auth delegation model
- Data validation conventions
- Transaction / consistency model

### ETL-specific: `spec/architecture/data-lineage.md`

*(ETL repos only)* End-to-end data lineage across all pipelines:
- Source systems → transformations → sink systems (Mermaid flowchart)
- Freshness SLAs per pipeline
- Idempotency guarantees
- Backfill support

---

## Phase 5 — Index Generation

Generate `spec/_index.md`: a catalog of all produced specs, their status,
domain, last-updated, and one-line description. This file is auto-generated
and will be regenerated on each run.

---

## Phase 6 — Verification

Invoke `spec-verify` sub-skill:

```
Run: skills/spec-verify/SKILL.md
Inputs:
  repo_path: {repo_path}
  repo_type: {repo_type}
```

If result is `NEEDS_WORK`:
1. Read `spec/.reverse-spec-coverage.md` for the list of uncovered
   entrypoints and failed checks.
2. Create targeted chunks for uncovered entrypoints only.
3. Re-run Phase 3 for those chunks.
4. Re-run Phase 6.
5. Iterate until `PASS` or until user decides to stop.

When `PASS`:
- Update all generated spec files: `status: draft` (they are drafts — a human
  must review and promote to `published`).
- Update `spec/.reverse-spec-state.json`: `status: completed`.
- Print final summary.

---

## Final Summary Format

```
Reverse-spec complete ✓
────────────────────────────────────────────────
Repo:         {repo_path}
Type:         {repo_type}
Chunks:       {N} domains analysed
Specs written:
  Features:       {N} files in spec/features/
  API:            {N} files in spec/api/
  Architecture:   {N} files in spec/architecture/
  Index:          spec/_index.md

Verification:   PASS ({coverage%} entrypoint coverage)

Open questions requiring human review: {N}
  → See ⚠️ markers in generated spec files.

Next steps:
  1. Review each spec/features/**/overview.md and resolve open questions.
  2. Change status from 'draft' to 'published' after review.
  3. Run spec-verify again after human review to confirm coverage.
  4. Commit spec/ directory to the repository.
────────────────────────────────────────────────
```

---

## Resumption Instructions

When invoked on a repo where `spec/.reverse-spec-state.json` exists:

```
Existing reverse-spec run found.
  Run ID:       {run_id}
  Started:      {started_at}
  Last updated: {last_updated}
  Phase:        {current_phase} ({phase name})
  Chunks:       {completed}/{total} complete

Options:
  R — Resume from phase {current_phase}
  F — Force restart from Phase 0 (will overwrite existing state)
  Q — Quit

Enter choice:
```
```
