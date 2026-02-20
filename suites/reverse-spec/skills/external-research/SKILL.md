---
name: external-research
version: 1.0.0
status: published
description: Researches external knowledge sources (Jira, Confluence, GitHub) for domains in a target repository and produces a structured findings document consumed by reverse-spec and spec-verify instead of re-querying sources; Slack and Google Docs support is planned for v2.
authors:
  - name: agent-dev team
created: 2026-02-20
last-updated: 2026-02-20
model: claude-haiku-4-5
# Rationale: external research is high-volume, low-complexity querying (search,
# paginate, extract snippets). A fast, cheap model is appropriate. Override
# explicitly so behaviour is predictable regardless of session model.
sources:
  v1:
    - Jira (via Atlassian MCP)
    - Confluence (via Atlassian MCP)
    - GitHub repositories (via github MCP)
  planned-v2:
    - Slack (no production MCP server available as of 2026-02-20)
    - Google Docs (MCP support too thin for reliable extraction)
inputs:
  - repo_path: absolute path to the target repository
  - product_name: human-readable name of the product/system (used as search seed)
  - domains: list of domain names identified during reverse-spec Phase 0 decomposition
  - jira_project_key: optional — Jira project key (e.g. AX, OX); skip if unknown
  - confluence_space_key: optional — Confluence space key; skip if unknown
  - github_dependency_repos: optional — list of "owner/repo" strings for known dependencies
output:
  file: spec/.external-research-findings.md   # written into the target repository
---

# External Research Skill

Gather intention, history, and dependency context for an existing codebase from
external knowledge sources. The output file is the **only artifact**: it is
written once and consumed by `reverse-spec` and `spec-verify` rather than
re-queried on every chunk.

---

## When to Use This Skill

- As **Phase 2** of the `reverse-spec` workflow (invoked automatically by the
  orchestrator after domain decomposition).
- Standalone, when you need to understand what decisions were made around a
  product before reading its code.

---

## Step-by-Step Execution

### Step 1 — Validate inputs

Check that `repo_path` exists and `spec/.external-research-findings.md` does
**not** already exist (do not overwrite a completed research run). If it exists,
report the cached path and stop.

### Step 2 — Jira research (if `jira_project_key` is provided)

For each domain in `domains`:

1. Use the Atlassian MCP to search Jira issues:
   - Query: `project = {jira_project_key} AND text ~ "{domain}" ORDER BY updated DESC`
   - Limit to 20 most recent results.
2. From each result extract: key, summary, status, issue type, resolution, and
   the **first paragraph of the description** (intention, not implementation).
3. Separately search for epics: `project = {jira_project_key} AND issuetype = Epic AND text ~ "{domain}"`
4. Record: epic keys + summaries, known acceptance criteria, any "why" language
   in descriptions.

If no `jira_project_key`, try a text search using `product_name` across
accessible projects.

### Step 3 — Confluence research (if `confluence_space_key` is provided)

For each domain in `domains`:

1. Search Confluence: `space = "{confluence_space_key}" AND text ~ "{domain}"`
   Limit to 10 results, ordered by `lastModified DESC`.
2. For each result: extract title, last-modified date, first 500 characters of
   body content, and any linked Jira issues.
3. Flag pages older than 365 days as potentially stale; still record them but
   annotate with `⚠️ stale`.

If no `confluence_space_key`, search by `product_name` across accessible spaces.

### Step 4 — GitHub dependency research

For each repo in `github_dependency_repos`:

1. Search for imports/references to `product_name` or known public identifiers
   (package names, proto service names, API path prefixes).
2. Note: which parts of the target repo are consumed externally (usage patterns
   inform what must be precisely specified).
3. Check README and any `docs/` or `spec/` directories for cross-repo contracts.

### Step 5 — Compile findings document

Write `spec/.external-research-findings.md` into the target repository.

#### Output format

```markdown
---
generated-by: external-research skill v1.0.0
generated-at: {ISO timestamp}
product: {product_name}
domains-researched: [{list}]
jira-project: {key or "not searched"}
confluence-space: {key or "not searched"}
github-deps: [{list}]
---

# External Research Findings: {product_name}

> This file is auto-generated. Do not edit manually.
> Consumed by: reverse-spec, spec-verify.

## Summary of Sources Searched

| Source | Status | Items Found |
|--------|--------|-------------|
| Jira | ✅ searched | N epics, M stories |
| Confluence | ✅ searched | N pages |
| GitHub ({repo}) | ✅ searched | N references |
| Slack | ⏭️ planned v2 | — |
| Google Docs | ⏭️ planned v2 | — |

---

## Domain: {domain-name}

### Jira Epics
- **{JIRA-KEY}**: {summary} (status: {status})
  - Intent: {first sentence of description}
  - Acceptance hints: {any AC language found}

### Jira Stories (top 5 by recency)
- **{JIRA-KEY}**: {summary}

### Confluence Pages
- **{title}** (last modified: {date}) {⚠️ stale if >365d}
  - Key content: {first 300 chars}

### GitHub References
- `{owner/repo}`: references `{identifier}` in {N} files
  - Notable usage: {one-line description}

### Key Decisions Discovered
- {Decision statement inferred from Jira/Confluence content}

### Unanswered Questions (gaps for spec to flag)
- {Question that cannot be answered from external sources}

---

## Cross-Domain Findings

Findings that span multiple domains or are product-wide:

- {Finding}

## Tribal Knowledge Gaps

Topics that appear in source code or config but have **no record** in any
searched external source. These must be flagged as explicit open questions in
the generated spec:

- {topic}: no Jira epic, no Confluence page, no GitHub doc found

### Step 6 — Report completion

Print a summary:
```
External research complete.
Output: {repo_path}/spec/.external-research-findings.md
Domains covered: {N}
Jira items found: {N}
Confluence pages found: {N}
GitHub references found: {N}
Tribal knowledge gaps identified: {N}
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Atlassian MCP unavailable | Log `JIRA_SKIPPED` / `CONFLUENCE_SKIPPED` in findings; continue |
| GitHub MCP unavailable | Log `GITHUB_DEPS_SKIPPED`; continue |
| No results found for a domain | Write empty section with note: "No external records found — treat all behaviour in this domain as tribal knowledge" |
| Output file already exists | Report path, do not overwrite, exit cleanly |

---

## v2 Planned Sources

When MCP servers for these sources become production-ready, add research steps:

- **Slack**: search by product name and domain keywords in relevant channels;
  extract decisions from threads.
- **Google Docs**: search Drive for design documents, PRDs, and meeting notes
  matching domain keywords.
```
