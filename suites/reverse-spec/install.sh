#!/usr/bin/env bash
# reverse-spec skill suite installer
# Usage: curl -fsSL https://raw.githubusercontent.com/sergseven/agent-dev/main/suites/reverse-spec/install.sh | bash
# Requirements: bash, curl, tar — all pre-installed on macOS and most Linux distros.

set -euo pipefail

REPO="sergseven/agent-dev"
BRANCH="main"
TARBALL_URL="https://api.github.com/repos/${REPO}/tarball/${BRANCH}"
SKILLS=(external-research reverse-spec spec-verify)
DEST_DIR=".agents/skills"

# ── colours (suppressed if not a tty) ──────────────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
else
  BOLD=''; GREEN=''; YELLOW=''; RESET=''
fi

echo ""
echo -e "${BOLD}reverse-spec skill suite installer${RESET}"
echo "────────────────────────────────────"
echo ""
echo -e "Install to : ${GREEN}${PWD}/${DEST_DIR}${RESET}"
echo -e "Compatible : GitHub Copilot · Codex CLI"
echo ""

# ── 1. confirm ──────────────────────────────────────────────────────────────────
read -rp "Proceed? Existing skills with the same name will be overwritten. [Y/n]: " confirm </dev/tty
confirm="${confirm:-Y}"
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── 2. download tarball into a temp directory ───────────────────────────────────
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo "Downloading ${REPO}@${BRANCH}..."
curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMP_DIR"

# GitHub tarballs extract to a directory named <user>-<repo>-<sha>/
EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d | tail -1)"

# ── 3. copy skills ──────────────────────────────────────────────────────────────
mkdir -p "$DEST_DIR"

for skill in "${SKILLS[@]}"; do
  SRC="${EXTRACTED_DIR}/suites/reverse-spec/skills/${skill}"
  DEST="${DEST_DIR}/${skill}"

  if [ ! -d "$SRC" ]; then
    echo -e "${YELLOW}Warning: skill '${skill}' not found in download — skipping.${RESET}"
    continue
  fi

  if [ -d "$DEST" ]; then
    echo "  overwriting ${DEST_DIR}/${skill}/"
    rm -rf "$DEST"
  else
    echo "  installing  ${DEST_DIR}/${skill}/"
  fi

  cp -r "$SRC" "$DEST"
done

# ── 4. summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Done.${RESET} Skills installed to ${DEST_DIR}/:"
for skill in "${SKILLS[@]}"; do
  echo "  + ${skill}"
done
echo ""
echo "Next steps:"
echo "  1. Open this project in VS Code"
echo "  2. Open Copilot Chat and switch to Agent mode"
echo "  3. Invoke: @reverse-spec"
echo ""
