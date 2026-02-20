#!/usr/bin/env bash
# conductor agent suite installer
# Usage: curl -fsSL https://raw.githubusercontent.com/sergseven/agent-dev/main/suites/conductor/install.sh | bash
# Requirements: bash, curl, tar — all pre-installed on macOS and most Linux distros.

set -euo pipefail

REPO="sergseven/agent-dev"
BRANCH="main"
TARBALL_URL="https://api.github.com/repos/${REPO}/tarball/${BRANCH}"
AGENTS=(Conductor Implementer Researcher Reviewer)

# ── colours (suppressed if not a tty) ──────────────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
else
  BOLD=''; GREEN=''; YELLOW=''; RESET=''
fi

echo ""
echo -e "${BOLD}conductor agent suite installer${RESET}"
echo "─────────────────────────────────"
echo ""

# ── 1. choose agent type ────────────────────────────────────────────────────────
echo "Which agent type are you installing for?"
echo "  1) GitHub Copilot  (installs to .github/agents/ in current project)"
echo ""
read -rp "Enter choice [1]: " agent_choice
agent_choice="${agent_choice:-1}"

case "$agent_choice" in
  1)
    AGENT_TYPE="copilot"
    DEST_DIR=".github/agents"
    ;;
  *)
    echo "Unknown choice '${agent_choice}'. Only option 1 (Copilot) is currently supported." >&2
    exit 1
    ;;
esac

echo ""
echo -e "Agent type : ${GREEN}${AGENT_TYPE}${RESET}"
echo -e "Install to : ${GREEN}${PWD}/${DEST_DIR}${RESET}"
echo ""

# ── 2. confirm ──────────────────────────────────────────────────────────────────
read -rp "Proceed? Existing agents with the same name will be overwritten. [Y/n]: " confirm
confirm="${confirm:-Y}"
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── 3. download tarball into a temp directory ───────────────────────────────────
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo "Downloading ${REPO}@${BRANCH}..."
curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMP_DIR"

# GitHub tarballs extract to a directory named <user>-<repo>-<sha>/
EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d | tail -1)"

# ── 4. copy agent definitions ───────────────────────────────────────────────────
mkdir -p "$DEST_DIR"

for agent in "${AGENTS[@]}"; do
  SRC="${EXTRACTED_DIR}/.github/agents/${agent}.agent.md"
  DEST="${DEST_DIR}/${agent}.agent.md"

  if [ ! -f "$SRC" ]; then
    echo -e "${YELLOW}Warning: agent '${agent}' not found in download — skipping.${RESET}"
    continue
  fi

  if [ -f "$DEST" ]; then
    echo "  overwriting ${DEST_DIR}/${agent}.agent.md"
  else
    echo "  installing  ${DEST_DIR}/${agent}.agent.md"
  fi

  cp "$SRC" "$DEST"
done

# ── 5. summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Done.${RESET} Agents installed to ${DEST_DIR}/:"
for agent in "${AGENTS[@]}"; do
  echo "  + ${agent}.agent.md"
done
echo ""
echo "Next steps:"
echo "  1. Open this project in VS Code"
echo "  2. Open Copilot Chat and switch to Agent mode"
echo "  3. Invoke: @Conductor"
echo ""
