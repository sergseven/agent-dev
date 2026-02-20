# agent-dev

This repository contains two independent things:

|                              | What it is                                             | Where it lives    | Portability                        |
|------------------------------|--------------------------------------------------------|-------------------|------------------------------------|
| **Agents**                   | Copilot sub-agent definitions used within this repo    | `.github/agents/` | Tied to this repo                  |
| **reverse-spec skill suite** | Portable skills for onboarding any repository into SDD | `skills/`         | Install into any VS Code workspace |

They do not depend on each other. You can use the reverse-spec skills on any repository without the agents, and the
agents work without the skills.

---

## Repository structure

```
agent-dev/
  .github/
    agents/               ← Copilot sub-agents for work within this repo
      Conductor.agent.md
      Implementer.agent.md
      Researcher.agent.md
      Reviewer.agent.md
  skills/                 ← standalone, portable skill suite (install anywhere)
    external-research/
      SKILL.md
    reverse-spec/
      SKILL.md
      prompts/
        chunk-analysis.md
        synthesize-spec.md
    spec-verify/
      SKILL.md
  sdd/
    spec-driven-development-workflow.md   ← SDD methodology and workflow definitions
  prompt/
    reverse-spec.md       ← design decisions and requirements for the skill suite
```

---

## Agents

Four Copilot sub-agent definitions live in `.github/agents/`. They are used by Copilot
agent mode **within this repository** to coordinate complex multi-step work:

| Agent         | Role                                                                    |
|---------------|-------------------------------------------------------------------------|
| `Conductor`   | Orchestrates planning and delegates to other sub-agents                 |
| `Researcher`  | Codebase discovery — reads files, searches, returns structured findings |
| `Implementer` | Executes focused code changes with validation                           |
| `Reviewer`    | Reviews changes and reports issues                                      |

These agents are repository-local. They are not installed or invoked on other repos.

### Installation

No manual installation needed. Copilot agent mode automatically discovers agent definitions from
`.github/agents/` when `agent-dev` is the open workspace in VS Code.

**Requirements:**

- VS Code with [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- Copilot Chat agent mode enabled (`"github.copilot.chat.agentMode": true` in VS Code settings)
- `agent-dev` open as the workspace root

---

## reverse-spec skill suite

> **Standalone and portable.** Install into any VS Code workspace — no dependency on `agent-dev`
> being open, on the agents above, or on any specific language or framework.

Generates a comprehensive SDD-compliant specification for an existing repository by analysing code, tests, config, and
external sources (Jira, Confluence, GitHub) in resumable chunks.

### Requirements

- VS Code with [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
  and [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat) extensions
  installed
- Copilot Chat agent mode enabled (`"github.copilot.chat.agentMode": true` in VS Code settings)
- MCP servers configured for your external sources (see [MCP configuration](#mcp-configuration) below)
- Target repository open in VS Code (single-folder or as a workspace folder)

---

### Installation

#### 1. Copy the skills into your VS Code user agents directory

```bash
# Create the agents directory if it does not exist
mkdir -p ~/.vscode/agents

# Copy all three skills
cp -r /path/to/agent-dev/skills/external-research ~/.vscode/agents/
cp -r /path/to/agent-dev/skills/reverse-spec ~/.vscode/agents/
cp -r /path/to/agent-dev/skills/spec-verify ~/.vscode/agents/
```

Or, if you have the `agent-dev` repo cloned alongside your target repos:

```bash
AGENT_DEV=~/dev/agent-dev

mkdir -p ~/.vscode/agents
cp -r $AGENT_DEV/skills/external-research ~/.vscode/agents/
cp -r $AGENT_DEV/skills/reverse-spec ~/.vscode/agents/
cp -r $AGENT_DEV/skills/spec-verify ~/.vscode/agents/
```

#### 2. Verify the structure

```
~/.vscode/agents/
  external-research/
    SKILL.md
  reverse-spec/
    SKILL.md
    prompts/
      chunk-analysis.md
      synthesize-spec.md
  spec-verify/
    SKILL.md
```

#### 3. MCP configuration

The `external-research` skill resolves GitHub lookups in this order:

1. **`gh` CLI** — used if `gh` is found in `PATH`. Faster, no MCP server required.
2. **GitHub MCP server** — fallback if `gh` is absent or not authenticated.

**Install and authenticate the `gh` CLI (recommended):**

```bash
brew install gh
gh auth login
```

For Atlassian (Jira + Confluence) and the GitHub MCP fallback, configure MCP servers in your VS Code
`settings.json` (`Cmd+Shift+P` → *Preferences: Open User Settings (JSON)*):

```jsonc
{
  "github.copilot.chat.mcp.servers": {
    // Atlassian (Jira + Confluence) — required for Jira epic and Confluence page lookup
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@atlassian/mcp-server"],
      "env": {
        "ATLASSIAN_BASE_URL": "https://your-org.atlassian.net",
        "ATLASSIAN_EMAIL": "you@your-org.com",
        "ATLASSIAN_API_TOKEN": "<your-api-token>"
      }
    },
    // GitHub MCP — only needed if gh CLI is not available
    "github": {
      "command": "npx",
      "args": ["-y", "@github/mcp-server"],
      "env": {
        "GITHUB_TOKEN": "<your-github-pat>"
      }
    }
  }
}
```

> Only configure the servers you have access to. The skill skips unavailable sources and records
> them as `unavailable` in the findings cache under `## Meta`.

---

### Usage

#### Basic invocation

1. Open the target repository in VS Code
2. Open Copilot Chat (`Cmd+I` or the chat panel)
3. Switch to **Agent mode**
4. Type:

```
@reverse-spec
```

The skill will prompt you for the repo type and begin Phase 0 (Discovery).

#### Specifying repo type upfront

```
@reverse-spec repo-type=etl
```

Accepted values: `protocol-defs` | `backend` | `api-heavy-backend` | `frontend-spa` | `frontend-monorepo` | `etl`

#### Running sub-skills independently

**External research only** (writes `spec/.external-research-findings.md`):

```
@external-research topics="deal ingestion, pricing engine" product="mgt-axiom"
```

**Verification only** (assumes specs already exist in `spec/`):

```
@spec-verify
```

**Verification with LLM deep-gap check** (slower, higher signal):

```
@spec-verify deep_check=true
```

---

### Resuming an interrupted run

If the skill is interrupted mid-run, a checkpoint file is written to:

```
<target-repo>/spec/.reverse-spec-state.json
```

Simply re-invoke the skill in the same workspace:

```
@reverse-spec
```

It will detect the state file, report which chunks are complete, and resume from the first pending chunk. To force a
fresh run and discard the previous state:

```
@reverse-spec reset=true
```

---

### Output structure

After a complete run, the following files are written into the target repository:

```
spec/
  _index.md                         ← catalog of all generated specs
  .reverse-spec-state.json          ← checkpoint file (safe to gitignore)
  .external-research-findings.md    ← external source cache (safe to gitignore)
  .reverse-spec-coverage.md         ← verification report
  architecture/
    system-overview.md
    non-functional.md
    cross-cutting-concerns.md
    data-lineage.md                 ← ETL repos only
  features/
    <domain>/
      overview.md                   ← one file per chunk/domain
  api/                              ← API-heavy backend and protocol-def repos
    <name>.md
```

#### Gitignore recommendation

Add the following to the target repo's `.gitignore`:

```gitignore
# reverse-spec working files
spec/.reverse-spec-state.json
spec/.external-research-findings.md
```

The coverage report (`spec/.reverse-spec-coverage.md`) and all `spec/**/*.md` outputs are intended to be committed.

---

### Verification thresholds

`spec-verify` applies three automated passes. A run is marked **PASS** when all three thresholds are met:

| Pass                        | Threshold | What it checks                                                  |
|-----------------------------|-----------|-----------------------------------------------------------------|
| Entrypoint coverage         | ≥ 80%     | Every public entrypoint has a matching spec reference           |
| Branch/conditional coverage | ≥ 75%     | Service-layer conditionals have a documented decision criterion |
| Test-to-spec mapping        | ≥ 70%     | Test names map to a spec acceptance criterion                   |

If any pass returns **NEEDS_WORK**, `reverse-spec` automatically runs additional chunks for the uncovered items and
re-invokes `spec-verify`. The loop continues until all thresholds are met or you stop it manually.

---

### Troubleshooting

| Symptom                                       | Likely cause                          | Fix                                                                                    |
|-----------------------------------------------|---------------------------------------|----------------------------------------------------------------------------------------|
| `external-research` finds nothing (GitHub)    | `gh` not installed or unauthenticated | Run `brew install gh && gh auth login`; or configure the GitHub MCP server as fallback |
| `external-research` finds nothing (Atlassian) | MCP server not running                | Check `settings.json`; run `npx @atlassian/mcp-server` manually to test                |
| Skill does not appear in agent mode           | Files not in `~/.vscode/agents/`      | Re-check installation path; restart VS Code                                            |
| State file not found on resume                | Wrong workspace folder active         | Ensure the target repo folder is the active workspace root                             |
| Coverage stuck below threshold                | NFRs only in infra configs            | Run `@spec-verify deep_check=true`; review flagged open questions manually             |