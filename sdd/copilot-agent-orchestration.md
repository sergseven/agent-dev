# Copilot Agent Orchestration Setup (VS Code 1.109+)

This workspace includes custom agents in `.github/agents` to enable a Claude Team-like orchestration flow in Copilot chat.

## What this gives you

- A coordinator agent: `Conductor`
- Specialized subagents: `Researcher`, `Implementer`, `Reviewer`
- Parallel subagent execution for independent workstreams

## Prerequisites

- VS Code 1.109 or newer
- GitHub Copilot with agent features enabled
- Third-party coding agents (Claude Agent / Codex) enabled in your Copilot subscription if you want those providers

## Workspace configuration already added

`/.vscode/settings.json`:

- `chat.customAgentInSubagent.enabled: true`
- `chat.agentFilesLocations` includes `.github/agents`, `.claude/agents`, and `/Users/serhii.nesprava/dev/agent-dev/.github/agents`

## How to use

1. Reload the VS Code window.
2. Open Copilot Chat.
3. In session target picker, select your provider (Copilot Agent, Claude Agent, or Codex where available).
4. In the agents dropdown, choose `Conductor`.
5. Start with a request such as:

   - `Implement feature X by first researching, then implementing, then reviewing.`
   - `Split work into parallel tracks for API, tests, and docs, then merge findings.`

## Verification checklist

- You can select `Conductor` in the agents list.
- Chat output shows subagent calls to `Researcher`, `Implementer`, and `Reviewer`.
- For split tasks, multiple subagents run in parallel before `Conductor` continues.

## Notes

- The orchestration pattern is supported by VS Code subagents and custom agents.
- Actual provider availability (Claude Agent / Codex) depends on your account entitlement and preview rollout.
