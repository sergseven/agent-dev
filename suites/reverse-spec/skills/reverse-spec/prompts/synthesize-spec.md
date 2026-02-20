# Synthesize-Spec Prompt Template

> Used by: `reverse-spec` Phase 3c  
> Apply to: the output of `chunk-analysis.md` for one domain.

---

## System Instructions (include verbatim)

You are converting structured analysis output into a Specification-Driven
Development (SDD) spec file. The output must be a single Markdown file that
conforms precisely to the SDD spec template. It must be complete enough that a
developer who has **never seen the original codebase** can reimplement this
domain solely from the spec you produce.

Write for two audiences simultaneously:
- **Product / QA / non-technical**: the Context, Goals, and Behaviour sections
  must be readable without engineering background.
- **Engineers / AI agents**: the API Contract, Data Model, Business Rules, and
  Acceptance Criteria sections must be unambiguous and precise.

Do not invent behaviour. If the chunk analysis contains an open question, carry
it forward as an explicit `⚠️ Open question` block.

---

## Input Variables

```
{domain}              — domain name (becomes file path and spec title)
{repo_name}           — repository name
{today}               — current date YYYY-MM-DD
{repo_type}           — one of: protocol-defs, backend, api-heavy, frontend-spa,
                        frontend-monorepo, etl
{analysis}            — full output of chunk-analysis.md for this domain
{jira_epic}           — Jira epic key if found in external research, else empty
{tags}                — comma-separated list of inferred tags
```

---

## Output: Complete SDD Spec File

Produce **exactly** the following structure. Do not add sections not in this
template. Do not omit sections (write "None identified." for empty ones).

````markdown
---
title: "{Capitalised domain name} — {one-line purpose}"
status: draft
generated-by: reverse-spec v1.0.0
authors: []
created: {today}
last-updated: {today}
domain: {domain}
repos:
  - {repo_name}
{jira-epic: {jira_epic}  ← include only if jira_epic is non-empty}
tags: [{tags}]
freshness-check: 90d
---

# {Capitalised domain name}

## Context & Scope

{2-4 sentences. What is this domain responsible for? What real-world concept
does it represent? What are its boundaries — what does it explicitly NOT own?
Written so a product manager can validate it.}

## Goals

{Bullet list. Each goal is a concrete capability the system provides.
Start each bullet with an action verb. 3-7 goals.}

## Non-Goals

{Bullet list. Explicit things this domain does NOT do. Include at least one.
If the chunk analysis found no evidence of a non-goal, infer one obvious
boundary based on separation of concerns.}

## Specification

### Behaviour

{For each BEHAVIOUR from chunk analysis STEP 1, write a prose paragraph or
sub-section. Format:}

#### {Behaviour name}

**Triggered by:** {trigger}  
**Preconditions:** {preconditions}  
**What happens:** {precise description of the operation in business language}  
**Postconditions:** {guaranteed outcome}  
**Side effects:** {external effects — events emitted, notifications sent, etc.}

{For ETL domains, replace with: PIPELINE sections from STEP 6 of analysis.}

### API Contract

{For each ENDPOINT/TOOL/TOPIC from STEP 2 of analysis:}

#### `{identifier}`

**Type:** {type}  
**Auth:** {auth requirement}

**Input:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| {field} | {type} | {yes/no} | {description} |

**Output:**

| Field | Type | Description |
|-------|------|-------------|
| {field} | {type} | {description} |

**Error responses:**

| Condition | Error / Status |
|-----------|----------------|
| {condition} | {error code or message} |

### Data Model

{For each ENTITY from STEP 3 of analysis, describe in business terms:}

#### {Entity name}

{One-sentence purpose.}

| Field | Type | Constraints | Business meaning |
|-------|------|-------------|------------------|
| {field} | {type} | {required, unique, etc.} | {plain-English meaning} |

Relationships: {describe relationships in prose}

### Business Rules

{For each RULE from STEP 4 of analysis:}

**Rule: {rule name}**  
Category: {category}  
When: {trigger condition}  
Then: {what happens}  
Otherwise: {what happens when condition is false, if relevant}

{For ETL: include conditional task/branch rules from DAG analysis.}

### Error Handling

{For each ERROR from STEP 5 of analysis:}

| Error | Trigger | Response | Consumer action |
|-------|---------|----------|-----------------|
| {error} | {condition} | {response} | {what to do} |

### Acceptance Criteria

{Derive directly from STEP 1 behaviours, STEP 4 rules, and STEP 5 errors.
Each criterion must be independently verifiable. Format as checkboxes.
Aim for complete coverage — every behaviour should have at least one criterion.}

- [ ] {criterion — specific, testable, free of implementation references}
- [ ] {criterion}
...

{For ETL: include data quality, idempotency, and SLA criteria.}

## NFRs

> Reference: [`spec/architecture/non-functional.md`](../architecture/non-functional.md)
> for repo-wide NFRs. Document only domain-specific overrides here.

{For each NFR signal from STEP 7 of analysis that is domain-specific:}

- **{NFR type}:** {description} *(confidence: {inferred|explicit})*

{For each NFR gap from STEP 7:}

> ⚠️ **NFR gap**: {missing NFR}. No evidence found in source or config.
> Requires domain expert review.

## Design Decisions

{If the external research or code analysis reveals architectural decisions
specific to this domain, document them in ADR style:}

### {Decision title}

**Context:** {why was a decision needed?}  
**Decision:** {what was decided?}  
**Consequences:** {what does this mean for the system?}  
**Alternatives considered:** {what else was evaluated?}

{If no design decisions are apparent, write: "No domain-specific design
decisions identified. See `spec/architecture/` for repo-wide decisions."}

## Open Questions

{For each OPEN item from STEP 8 of analysis:}

> ⚠️ **Open question**: {question text}  
> Evidence: {evidence of gap}  
> Suggested source: {where to find the answer}

{If none: write "None identified — all observed behaviour is explained." }

## Related

- Architecture: [`spec/architecture/system-overview.md`](../architecture/system-overview.md)
{- API spec: [`spec/api/{name}.md`](../api/{name}.md)  ← include if this domain has API contract docs}
{- Cross-repo: [{link}]({path})  ← include if cross-repo features are referenced}
{- Jira epic: [{jira_epic}](https://jira.company.com/browse/{jira_epic})  ← include only if jira_epic non-empty}
````

---

## Post-Generation Quality Check

After generating the spec, verify:

- [ ] Every entrypoint from the chunk analysis appears under **API Contract**.
- [ ] Every RULE from the analysis appears under **Business Rules**.
- [ ] Every BEHAVIOUR has at least one **Acceptance Criterion**.
- [ ] Every OPEN question appears under **Open Questions**.
- [ ] The YAML frontmatter is valid: `status: draft`, `created` and
     `last-updated` are set to `{today}`, `generated-by` is set.
- [ ] No implementation details (class names, SQL text, internal method names)
     appear outside the API Contract section.
- [ ] All ⚠️ markers are preserved from the analysis output.
