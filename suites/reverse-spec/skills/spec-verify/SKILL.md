```skill
---
name: spec-verify
version: 1.0.0
status: published
description: >
  Verifies structural coverage of a generated spec/ directory against the actual
  codebase. Checks that every public entrypoint is documented, every service-layer
  branch has a spec scenario, and every test has a matching acceptance criterion.
  Optionally runs an LLM-based "new developer questions" deep-gap check.
  Returns PASS (≥80% coverage) or NEEDS_WORK with a detailed coverage report.
authors:
  - name: agent-dev team
created: 2026-02-20
last-updated: 2026-02-20
# model: not set — inherits the session model.
# Rationale: branch coverage analysis and test-to-spec semantic matching benefit
# from strong reasoning. Deep gap check (Pass 4) especially requires a capable
# model; do not override unless the session model is intentionally downgraded.
inputs:
  repo_path: absolute path to the target repository
  repo_type: "one of: protocol-defs, backend, api-heavy, frontend-spa, frontend-monorepo, etl"
  deep_check: "optional boolean (default: false) — run the expensive LLM gap check"
outputs:
  result: "PASS | NEEDS_WORK"
  coverage_report: spec/.reverse-spec-coverage.md
---

# Spec-Verify Skill

Performs three verification passes against a generated `spec/` directory.
Produces `spec/.reverse-spec-coverage.md` with a detailed gap report for use
by `reverse-spec` Phase 6.

---

## When to Use This Skill

- Automatically, as Phase 6 of the `reverse-spec` workflow.
- Standalone, to audit an existing `spec/` directory for gaps.
- Before promoting any spec from `draft` to `published`.

---

## Pass 1 — Entrypoint Coverage

### Goal

Confirm every **public entrypoint** detected in the codebase is referenced in
at least one spec file under `spec/`.

### Detection (language-agnostic, config-first)

Use the same config/wiring signals as `reverse-spec` Phase 1. Additionally,
apply source-code name-pattern scanning as a supplemental signal:

| Repo type | Entrypoints to detect | Primary signal |
|-----------|----------------------|----------------|
| Protocol defs | All `rpc` methods in all `.proto` / `service` blocks in `.thrift` | Definition files |
| Backend | All exported HTTP route registrations + message consumers + scheduled tasks | Router/config files |
| API-heavy backend | All HTTP routes + GraphQL `Query/Mutation/Subscription` fields + MCP `@Tool` methods | Route files + schema files + tool annotations |
| Frontend SPA | All top-level routes in router config | Router config file |
| Frontend monorepo | All routes per package | Per-package router config |
| ETL | All DAG/flow objects defined in `dags/` / `flows/` / `pipelines/` | DAG definition files |

### Spec search

For each detected entrypoint, search spec files for:
1. The exact endpoint path, method name, tool name, topic name, or DAG name.
2. A semantic equivalent (allow for minor naming differences if the URL/name is
   clearly the same concept).

Record each entrypoint as `covered` or `uncovered`.

### Coverage threshold

- `PASS`: ≥ 80% of entrypoints covered.
- `NEEDS_WORK`: < 80% covered.

---

## Pass 2 — Business Logic Branch Coverage

### Goal

Confirm that every **material branch or decision** in service/domain-layer code
has a corresponding spec scenario (business rule, acceptance criterion, or
behaviour variant).

### Scope

Scan files in service/domain/use-case layers only (not controllers, not
infrastracture adapters). Identify:

- `if/else` conditions that route to meaningfully different outcomes.
- `switch/match` cases.
- Validation guards that throw/return errors.
- State machine transitions.
- ETL: `BranchOperator`, conditional task execution, `trigger_rule` variations.

**Exclude:**
- Pure technical branches: null checks, defensive programming, logging.
- Branches inside test code itself.

### Spec search

For each identified branch decision, check that the spec for the owning domain
contains a Business Rule, Behaviour variant, or Acceptance Criterion that covers
the decision condition.

Record each branch as `specified` or `unspecified`.

### Threshold

- `PASS`: ≥ 75% of material branches have a corresponding spec entry.
- `NEEDS_WORK`: < 75%, or any branch results in a spec scenario that would be
  testable but has no Acceptance Criterion.

---

## Pass 3 — Test-to-Spec Mapping

### Goal

Confirm that every test's **purpose** is captured in at least one spec Acceptance
Criterion. Tests are the most honest record of developer intent; unmapped tests
indicate spec gaps.

### Test detection

Find test files (language-agnostic):

| Signal | File patterns |
|--------|--------------|
| Python | `test_*.py`, `*_test.py`, `conftest.py` |
| Java | `*Test.java`, `*Tests.java`, `*Spec.java` |
| Go | `*_test.go` |
| JavaScript/TypeScript | `*.test.ts`, `*.spec.ts`, `*.test.js`, `*.spec.js` |
| Erlang | `*_SUITE.erl`, `*_tests.erl` |

### Test name extraction

Extract the **human-readable test name** from each test:
- Python: `def test_{name}`, `class Test{Name}`, `@pytest.mark` descriptions
- Java: `@Test`, `@DisplayName`, method name
- Go: `func Test{Name}`
- JS/TS: `it(...)`, `test(...)`, `describe(...)` strings
- Erlang: function names in `all()` list

Normalise the name to plain English (replace underscores with spaces, strip
`test_` prefix).

### Spec search

For each normalised test name, check that the domain's spec contains an
Acceptance Criterion, Behaviour, or Business Rule that covers the same scenario.
Allow semantic matching — "creates app category with valid input" maps to
"Creates an app category".

Record each test as `mapped` or `unmapped`.

### Threshold

- `PASS`: ≥ 70% of tests have a matching spec entry.
- `NEEDS_WORK`: < 70%.

---

## Pass 4 — Deep Gap Check (optional, `deep_check: true`)

### Goal

Find intent gaps that static analysis cannot detect: things that are specified
but underspecified, or behaviours that are implied but never articulated.

### Method

For each domain spec file, send a request:

```
System: You are an experienced developer who has read only this specification
and must implement this feature from scratch, with no other context.

User: Read the spec below. List every question you would need answered before
you could safely implement this feature. Be specific. Focus on:
- Ambiguous behaviour descriptions
- Missing error cases
- Unspecified concurrency or ordering constraints
- Unclear authentication or authorisation requirements
- Unspecified data validation rules
- Missing cross-domain contracts
Do not ask about implementation choices — only about missing specification.

Spec:
{spec file content}
```

Record all questions as `deep_gaps` in the coverage report.

This pass does not affect the `PASS` / `NEEDS_WORK` result — it is advisory.

---

## Coverage Report Output

Write `spec/.reverse-spec-coverage.md`:

```markdown
---
generated-by: spec-verify v1.0.0
generated-at: {ISO timestamp}
repo: {repo_path}
repo_type: {repo_type}
overall_result: PASS | NEEDS_WORK
---

# Spec Coverage Report

## Summary

| Pass | Items Checked | Covered | Coverage | Result |
|------|--------------|---------|----------|--------|
| Entrypoint coverage | {N} | {N} | {N}% | ✅ PASS / ❌ NEEDS_WORK |
| Branch coverage | {N} | {N} | {N}% | ✅ PASS / ❌ NEEDS_WORK |
| Test-to-spec mapping | {N} | {N} | {N}% | ✅ PASS / ❌ NEEDS_WORK |
| Deep gap check | {N domains} | advisory | — | ℹ️ {N} gaps |

**Overall: PASS / NEEDS_WORK**

---

## Pass 1: Uncovered Entrypoints

{List of uncovered entrypoints with suggested spec location:}

| Entrypoint | Type | Domain (inferred) | Suggested spec path |
|-----------|------|-------------------|---------------------|
| {identifier} | {type} | {domain} | spec/features/{domain}/overview.md |

---

## Pass 2: Unspecified Branches

| Location (file pattern) | Branch condition | Domain | Missing spec entry |
|------------------------|-----------------|--------|-------------------|
| {file} | {condition} | {domain} | Business Rule in spec/features/{domain}/overview.md |

---

## Pass 3: Unmapped Tests

| Test name | File | Domain | Missing spec entry |
|-----------|------|--------|-------------------|
| {test name} | {file} | {domain} | Acceptance Criterion in spec/features/{domain}/overview.md |

---

## Pass 4: Deep Gap Check (advisory)

### Domain: {domain}

- {question}
- {question}

---

## Action Items for reverse-spec

{If NEEDS_WORK, list the domains to re-process as additional chunks:}

Priority domains for re-analysis:
1. {domain} — {N} uncovered entrypoints / {N} unspecified branches
2. {domain} — {N} uncovered entrypoints
```

---

## Return Values

```
result: PASS        → reverse-spec Phase 6 concludes successfully
result: NEEDS_WORK  → reverse-spec reads this report, creates targeted chunks,
                      re-runs Phase 3 for listed domains, then calls spec-verify again
```
```
