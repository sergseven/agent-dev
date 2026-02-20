# GitBook Workflow for Specs (Non-Technical Contributors)

**Purpose**: Enable PMs, QA, and other stakeholders to **read** and **propose changes** to system specifications that live in Git (`spec/`), without using Git locally.

**Policy:** Every spec change must be proposed as a **GitHub Pull Request (PR)** and go through normal repo review rules (CODEOWNERS, branch protections, required reviewers).

This guide treats **GitBook primarily as the reading/search portal**. For proposing changes, we use a PR-first workflow (Gemini Workspace agent or GitHub web UI).

---

## What GitBook is in this setup

- **Git (repo `spec/`) is the source of truth**.
- **GitBook is the UI** on top of that source of truth:
  - Searchable, easy-to-read portal
  - Google-Docs-like editing
   - A friendly place to draft content (optional), but **not the source of merge authority**

### What you can do

- Read current behavior (“what the system does”) in `spec/`
- Propose corrections or product changes (behavior, goals, acceptance criteria) via PR
- Start a new spec draft (with help from engineering for technical sections)

### What you should not do

- Don’t change implementation code (`src/`) in GitBook
- Don’t force-merge controversial changes: GitBook edits still require engineering review
- Don’t rely on “edited in GitBook” as “approved” — only a merged GitHub PR changes the spec

---

## Where specs live (how to find the right page)

Specs are organized by **domain** and identified by their **path**:

- Feature specs: `spec/features/<domain>/<short-name>.md`
- Cross-repo specs: `spec/cross-repo/<short-name>.md`
- Architecture decisions: `spec/architecture/ADR-###-<short-name>.md`

In GitBook, the navigation should mirror this structure.

---

## Routing rules (which repo / cross-repo)

Non-technical contributors should not need to decide repo ownership up front.

**Rule 1: If you know the domain, start there.**
- Pick the closest domain folder in `spec/features/<domain>/`.

**Rule 2: If you don’t know the repo/domain, use “Triage”.**
- Open a PR via the Gemini Workspace Spec Agent and say: “I don’t know where this belongs.”
- Engineering routes it during review (move/rename the file as needed).

**Rule 3: If the change spans multiple repos, create a single cross-repo spec.**
- Create or update `spec/cross-repo/<short-name>.md` in the chosen “home” repo.
- In the spec frontmatter, list the affected repos (e.g., `repos: [mgt-axiom-server, ox-api-core, deal-troubleshooting-agent]`).
- Create Jira work items per repo that reference the same cross-repo spec.

**Default “home” repo (initially):** `mgt-axiom-server`.

Why: it avoids analysis paralysis for requesters; the cost of moving a Markdown file during review is low.

---

## Reading workflow (fast path)

1. Open GitBook and use **Search** for the feature/domain (e.g., “app category”, “mcp”, “bigquery”).
2. Confirm you’re reading the right spec by checking:
   - Title
   - Domain
   - Linked Jira epic (if present)
   - Last updated date
3. If something looks wrong or unclear, propose a change (next section).

---

## Proposing a change (edit existing spec)

### When to propose a spec change

Use GitBook edits when you want to change or clarify:

- Desired behavior
- Edge cases
- Acceptance criteria
- Non-goals (what we explicitly won’t do)
- Terminology / definitions

### Step-by-step

1. Open the spec page in GitBook.
2. Decide how you want to open the PR:
   - **Recommended (non-technical):** Ask the **Gemini Workspace Spec Agent** to open a PR for you (Google Chat or Form).
   - **Alternative (hands-on):** Use **GitHub web editor** to edit the Markdown file and create a PR.
3. In your request, include:
   - The spec path (from GitBook navigation)
   - What changed
   - Why it changed
   - Any deadlines or rollout concerns

### What happens next (engineering review)

- Engineers review the PR like any code change.
- Review comments show up on the PR; you can respond by replying in the PR conversation.
- When approved, engineering merges it.

### After merge

- GitBook updates automatically from `main`.
- The spec is now authoritative; implementation work can be planned/tracked from it.

---

## Gemini Workspace Spec Agent workflow (recommended)

This is the default path for non-technical contributors when PRs are mandatory.

1. In Google Chat (or via a Google Form), describe:
   - Which spec to change (paste the path from GitBook navigation)
   - What you want to change (new behavior / acceptance criteria)
   - Why
2. The agent drafts the Markdown change and opens a GitHub PR.
3. You receive a PR link to review.
4. Engineering reviews/requests changes.
5. When merged, GitBook updates.

---

## Creating a new spec (non-technical draft)

You have two supported options.

### Option A (recommended): Intake form / Chat request → auto PR

1. Fill an intake form (title, domain, problem, goals, non-goals, acceptance criteria).
2. Automation creates a GitHub PR with a draft spec in the right folder.
3. You and engineering refine it until it’s ready.

### Option B: GitHub web editor → PR

1. Ask engineering for the correct target folder (domain).
2. Create a new Markdown file in GitHub web UI.
3. Open a PR.

**Tip**: If you’re not sure where it belongs, pick the closest domain. Engineering can move/rename during review.

---

## How to write acceptance criteria (the part that matters most)

Good acceptance criteria are:

- Specific and testable
- Written as observable behavior
- Focused on outcomes (not implementation)

Examples:

- ✅ “User can create an app category with a name and account, and sees it in search within 5 seconds.”
- ✅ “If account doesn’t have permission, the tool returns a clear error message and does not mutate data.”
- ❌ “Implement caching” (this is a design choice, not acceptance behavior)

---

## Jira linkage (how Jira and GitBook coexist)

- Jira remains the place for **who/when/status**.
- The spec remains the place for **what/why/acceptance criteria**.

Recommended practice:

- The spec frontmatter includes a Jira epic key (e.g., `jira-epic: AX-1234`).
- The Jira epic links back to the spec URL in GitBook.

---

## Keeping Jira features (planning, assignments, estimates) with SDD

SDD does **not** replace Jira. It changes what Jira is used for.

### Source of truth split

- **Spec (Git + PR)**: requirements and acceptance criteria (what/why)
- **Jira**: planning and coordination (who/when/status/estimates)

### Minimal Jira fields that stay meaningful

- Epic/Initiative: timeline, priority, ownership, high-level scope
- Stories/Tasks: assignments, estimates, sprint planning, dependencies

### Required links (so Jira stays connected to reality)

- Every Epic must link to exactly one spec (feature spec or cross-repo spec).
- Every Story/Task must link to the same spec and specify the slice it implements.

### Definition of Ready (DoR) for a Jira Story

Before a Story can be taken into a sprint, it must have:

- Linked spec PR merged (or an explicitly approved “draft spec” PR if you allow implementation in parallel)
- Acceptance criteria in the spec that is reviewable by the PO/QA
- Clear repo ownership (or cross-repo spec)

### Definition of Done (DoD)

A Story is done when:

- Code is merged
- Tests match acceptance criteria
- Spec is updated in the same PR if implementation revealed gaps (still PR-based)

---

## Common questions / failure modes

### “Who should issue a spec change?”

- **Anyone can request** a spec change (PO/QA/Stakeholder/Engineer) via the Gemini Workspace Spec Agent.
- **Engineers are responsible for merging** (and for ensuring it is implementable and consistent with architecture).
- **PO/QA are responsible for approving behavior/acceptance criteria** (they are the customer of the behavior).

Practical rule: if a PR changes “Behavior” or “Acceptance Criteria”, add/require a PO/QA reviewer (or a label-based approval rule).

### “What if non-technical people don’t adopt writing specs?”

SDD still works, but you must make the ownership explicit:

- Engineers can draft specs, but **PO must validate** the behavior and acceptance criteria in the PR.
- If PO won’t review specs, you’ll regress to “engineers guessing requirements,” which is the same failure mode as today.

To reduce friction:

- Keep specs short (“spec-lite”): Context, Goals, Behavior, Acceptance Criteria.
- Use the Gemini agent to convert a Jira description into a first spec draft PR.
- Make spec review a normal part of refinement: “ticket refinement ends when spec section is approved.”

### “What if two people edit the same spec?”

- There will be separate PRs.
- If both touch the same lines, Git may produce a merge conflict.
- Engineering resolves conflicts during PR review/merge. If needed, you’ll be asked to re-apply your change on top of the merged version.

### “Can I break formatting?”

- Basic Markdown formatting is safe.
- Avoid editing YAML frontmatter unless you know what it is.
- If you must change metadata (domain/status/jira key), add a note in the PR description; engineering can adjust it safely.

### “How do we know the spec is still accurate?”

- Specs are reviewed via PR like code.
- CI can enforce that behavior changes require spec updates.
- Specs have `last-updated` and staleness checks (policy-driven).

---

## Checklist before you submit a PR

- The change describes **behavior** and/or **acceptance criteria** clearly.
- Non-goals are updated if scope changed.
- You added a short “why” in the PR description.
- You linked the relevant Jira epic/story (or wrote “TBD”).
