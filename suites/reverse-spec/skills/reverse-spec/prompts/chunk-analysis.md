# Chunk Analysis Prompt Template

> Used by: `reverse-spec` Phase 3b  
> Apply to: collected source files for one domain chunk + external research findings for that domain.

---

## System Instructions (include verbatim)

You are performing deep business-logic analysis of a specific domain within an
existing codebase. Your goal is to extract everything a developer would need to
know to **reimplement this domain from scratch**, relying only on the output you
produce.

You are **not** summarising the code. You are producing **precise, implementation-
independent specifications** of behaviour, contracts, and rules. Omit
implementation details (class names, method names, variable names, framework
internals) unless they form part of a public contract.

---

## Input Variables

```
{domain}              — name of the domain being analysed
{repo_type}           — one of: protocol-defs, backend, api-heavy, frontend-spa,
                        frontend-monorepo, etl
{source_files}        — concatenated content of all source files for this domain
{test_files}          — concatenated content of test files for this domain
{external_findings}   — the domain section from spec/.external-research-findings.md
{entrypoints}         — list of entrypoints identified in Phase 1 for this domain
```

---

## Analysis Instructions

Work through the following extraction steps. Output each step as a clearly
labelled section. Do not skip a section — write "none found" if truly empty.

---

### STEP 1: Public Behaviours

List every distinct thing this domain **does** from the perspective of its
consumers. Write each behaviour as:

```
BEHAVIOUR: {imperative verb phrase in business language}
Triggered by: {what causes this — HTTP call / event / schedule / DAG trigger}
Preconditions: {what must be true before this can succeed}
Postconditions: {guaranteed state of the world after success}
Side effects: {external calls, events emitted, data written}
```

Focus on **what**, never on **how**. If the code contains a
`createAppCategory()` method, the behaviour is "Creates an app category with a
name scoped to an account" — not "calls createAppCategory()".

---

### STEP 2: API Surface

For each entrypoint listed in `{entrypoints}`, document the contract:

```
ENDPOINT/TOOL/TOPIC: {exact identifier as a consumer would reference it}
Type: {HTTP GET|POST|... / gRPC method / MCP tool / Kafka topic / DAG trigger / etc.}
Input: {parameters / payload shape — describe fields, types, required/optional}
Output: {response shape / emitted event shape — describe fields and types}
Error cases: {what conditions produce each distinct error response}
Auth / access control: {who can call this}
```

For ETL chunks: replace ENDPOINT with DAG/TASK and document trigger conditions,
input parameters, output datasets/tables, and retry/SLA configuration.

---

### STEP 3: Data Entities

For each entity that this domain owns or mutates:

```
ENTITY: {name}
Purpose: {one sentence — what real-world concept does this represent?}
Key fields: {field name — type — business meaning — constraints/invariants}
Relationships: {other entities this relates to and how}
Ownership: {this domain owns it / shared / read-only from another domain}
```

If the domain reads a schema from a database migration or ORM model, describe
the schema in business terms, not as SQL column definitions.

---

### STEP 4: Business Rules

List **every explicit decision** found in the domain's service/logic layer. For
each `if/else`, `switch`, validation guard, permission check, state machine
transition, or pricing/calculation logic:

```
RULE: {plain-English statement of the rule}
Category: {validation | permission | state-transition | calculation | routing}
Trigger condition: {when does this rule apply?}
Decision: {what happens when the condition is true? what happens when false?}
Source signal: {brief code location hint, e.g. "service layer, order processing"}
```

This is the most critical section. Missed rules here mean the generated spec
cannot be used to reimplement the system. Be exhaustive.

---

### STEP 5: Error Scenarios

For each distinct error or exception path:

```
ERROR: {error name or code}
Trigger: {precise condition that causes this error}
Response to consumer: {HTTP status / error message shape / event emitted}
Recovery hint: {what should a consumer do? retry, fix input, contact support?}
```

---

### STEP 6: ETL-Specific (skip if not ETL)

```
PIPELINE: {DAG/flow name}
Business trigger: {what real-world event or schedule initiates this?}
Source data: {where does input data come from — tables, APIs, files, topics}
Transformations: {describe each logical transformation step in business terms}
Output data: {where does processed data land — tables, files, topics}
Business rules in transforms: {filters, deduplication, enrichment, calculations}
Idempotency: {is re-running safe? under what conditions?}
SLA / freshness: {when must output data be ready?}
Backfill support: {can historical data be reprocessed?}
```

---

### STEP 7: NFR Signals

Record any observable performance, security, or reliability characteristics:

```
NFR: {latency / throughput / SLO / auth mechanism / retry / rate-limit / etc.}
Evidence: {where in config or code was this found?}
Confidence: {inferred / explicit}
```

If an NFR is _expected_ for this domain type but **not found in code or config**,
record it as a gap:
```
NFR GAP: {expected NFR not found — e.g. "no retry policy found for async consumer"}
```

---

### STEP 8: Unanswered Questions

For each of the following, write a question if the answer cannot be determined
from source code or external research:

- Why was this domain designed this way? (intent, not mechanism)
- What alternative approaches were rejected?
- What constraints does this domain impose on its consumers?
- Are there known limitations or technical debt items?
- What edge cases does the code handle but not explain?

```
OPEN: {precise question}
Evidence of gap: {what in code suggests this question exists?}
Suggested source: {Jira / Confluence / domain expert}
```

---

## Quality Check

Before finalising your output, verify:

- [ ] Every entrypoint from `{entrypoints}` appears in STEP 2.
- [ ] Every `if/else` and validation guard in service-layer code appears in STEP 4.
- [ ] Every distinct exception type or error response appears in STEP 5.
- [ ] For ETL: every branch operator or conditional task appears in STEP 4.
- [ ] No implementation detail (class name, SQL query text, internal method
      name) appears in STEP 1–5 unless it forms part of a public API contract.
