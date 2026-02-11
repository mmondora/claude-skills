#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# build-zip.sh
# Builds a versioned claude-skills zip for distribution.
# Extracts the version from the first SKILL.md it finds,
# then packages all skills into scripts/claude-skills-<version>.zip.
#
# Usage:
#   ./scripts/build-zip.sh
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"

# ── Colors ──
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Extract version from first SKILL.md ──
VERSION=""
for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  VERSION=$(grep -m1 'Version' "$skill_file" 2>/dev/null \
    | sed 's/.*Version[*]*: *\([0-9][0-9.]*\).*/\1/' || true)
  [ -n "$VERSION" ] && break
done

if [ -z "$VERSION" ]; then
  echo -e "${RED}Error: could not extract version from any SKILL.md${NC}"
  exit 1
fi

# ── Remove old versioned zips ──
rm -f "${SCRIPT_DIR}"/claude-skills-*.zip

# ── Build curated zip ──
ZIP_NAME="claude-skills-${VERSION}.zip"
ZIP_PATH="${SCRIPT_DIR}/${ZIP_NAME}"

echo -e "${CYAN}Building ${BOLD}${ZIP_NAME}${NC}..."

(cd "$REPO_ROOT" && zip -qr "$ZIP_PATH" .claude/skills/)

SKILL_COUNT=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

echo -e "${GREEN}Created ${ZIP_PATH}${NC}"
echo -e "${GREEN}${SKILL_COUNT} curated skills, version ${VERSION}${NC}"

# ── Build full zip (curated + community) ──
COMMUNITY_DIR="${REPO_ROOT}/community"
if [ -d "${COMMUNITY_DIR}/skills" ]; then
  FULL_ZIP_NAME="claude-skills-${VERSION}-full.zip"
  FULL_ZIP_PATH="${SCRIPT_DIR}/${FULL_ZIP_NAME}"

  echo ""
  echo -e "${CYAN}Building ${BOLD}${FULL_ZIP_NAME}${NC} (curated + community)..."

  (cd "$REPO_ROOT" && zip -qr "$FULL_ZIP_PATH" .claude/skills/ community/)

  COMMUNITY_COUNT=$(find "${COMMUNITY_DIR}/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${GREEN}Created ${FULL_ZIP_PATH}${NC}"
  echo -e "${GREEN}${SKILL_COUNT} curated + ${COMMUNITY_COUNT} community skills${NC}"
fi
