#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# install-skills.sh
# Installs Claude Code skills into a target project.
# Unpacks skills from claude-skills.zip into <target>/.claude/skills/
# and optionally patches/creates CLAUDE.md with skill references.
#
# Usage:
#   ./scripts/install-skills.sh <target-project-path> [--no-patch] [--force]
#
# Options:
#   --no-patch   Skip CLAUDE.md patching (only install skills)
#   --force      Overwrite existing skills without prompting
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_ZIP="${REPO_ROOT}/claude-skills.zip"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Parse arguments ──
TARGET=""
NO_PATCH=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --no-patch) NO_PATCH=true ;;
    --force) FORCE=true ;;
    --help|-h)
      echo -e "${BOLD}claude-skills installer${NC}"
      echo ""
      echo "Usage: ./scripts/install-skills.sh <target-project-path> [--no-patch] [--force]"
      echo ""
      echo "Options:"
      echo "  --no-patch   Skip CLAUDE.md patching (only install skills)"
      echo "  --force      Overwrite existing skills without prompting"
      echo ""
      echo "This script unpacks 23 Claude Code skills from claude-skills.zip"
      echo "into <target>/.claude/skills/ and optionally adds a skill reference"
      echo "table to the target project's CLAUDE.md."
      exit 0
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$arg"
      else
        echo -e "${RED}Error: unexpected argument '$arg'${NC}"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo -e "${RED}Error: target project path is required${NC}"
  echo "Usage: ./scripts/install-skills.sh <target-project-path> [--no-patch] [--force]"
  exit 1
fi

# Resolve to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  echo -e "${RED}Error: directory '$TARGET' does not exist${NC}"
  exit 1
}

echo -e "${BOLD}claude-skills installer${NC}"
echo -e "${CYAN}Target:${NC} $TARGET"
echo ""

# ── Verify zip exists ──
if [ ! -f "$SKILLS_ZIP" ]; then
  echo -e "${RED}Error: claude-skills.zip not found at $SKILLS_ZIP${NC}"
  echo "Run this script from the claude-skills repo root."
  exit 1
fi

# ── Create target .claude/skills/ ──
SKILLS_TARGET="${TARGET}/.claude/skills"

# ── Check for existing skills ──
if [ -d "$SKILLS_TARGET" ] && [ "$FORCE" = false ]; then
  EXISTING=$(find "$SKILLS_TARGET" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [ "$EXISTING" -gt 0 ]; then
    echo -e "${YELLOW}Found ${EXISTING} existing skill(s) in ${SKILLS_TARGET}${NC}"
    echo -e "${YELLOW}Use --force to overwrite, or skills will be merged (new files added, existing updated).${NC}"
    echo ""
  fi
fi

# ── Unpack zip ──
echo -e "${CYAN}Unpacking skills...${NC}"

# Create a temp dir for extraction
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

unzip -q "$SKILLS_ZIP" -d "$TMPDIR"

# The zip contains .claude/skills/<name>/SKILL.md
EXTRACTED="${TMPDIR}/.claude/skills"

if [ ! -d "$EXTRACTED" ]; then
  echo -e "${RED}Error: unexpected zip structure — expected .claude/skills/ inside zip${NC}"
  exit 1
fi

# ── Install skills ──
INSTALLED=0
UPDATED=0
SKIPPED=0

mkdir -p "$SKILLS_TARGET"

for skill_dir in "$EXTRACTED"/*/; do
  skill_name="$(basename "$skill_dir")"

  # Skip hidden files
  [[ "$skill_name" == .* ]] && continue

  skill_target="${SKILLS_TARGET}/${skill_name}"

  if [ -d "$skill_target" ]; then
    if [ "$FORCE" = true ]; then
      rm -rf "$skill_target"
      cp -r "$skill_dir" "$skill_target"
      echo -e "  ${GREEN}[updated]${NC} ${skill_name}"
      UPDATED=$((UPDATED + 1))
    else
      # Merge: update SKILL.md if it exists, add if new
      cp -r "${skill_dir}"* "$skill_target/"
      echo -e "  ${GREEN}[merged]${NC}  ${skill_name}"
      UPDATED=$((UPDATED + 1))
    fi
  else
    cp -r "$skill_dir" "$skill_target"
    echo -e "  ${GREEN}[new]${NC}     ${skill_name}"
    INSTALLED=$((INSTALLED + 1))
  fi
done

echo ""
echo -e "${GREEN}New: ${INSTALLED}  |  Updated: ${UPDATED}  |  Total: $((INSTALLED + UPDATED)) skills${NC}"

# ── Patch CLAUDE.md ──
if [ "$NO_PATCH" = true ]; then
  echo ""
  echo -e "${CYAN}Skipping CLAUDE.md patch (--no-patch)${NC}"
else
  CLAUDE_MD="${TARGET}/CLAUDE.md"
  MARKER="<!-- claude-skills:begin -->"
  MARKER_END="<!-- claude-skills:end -->"

  # Build the skills reference block
  SKILLS_BLOCK="${MARKER}
## Installed Skills

The following Claude Code skills are installed in \`.claude/skills/\`. Claude will auto-load them based on context, or you can invoke them with \`/<skill-name>\`.

| Skill | Description |
|-------|-------------|"

  for skill_dir in "$SKILLS_TARGET"/*/; do
    skill_name="$(basename "$skill_dir")"
    [[ "$skill_name" == .* ]] && continue

    skill_file="${skill_dir}SKILL.md"
    if [ -f "$skill_file" ]; then
      # Extract description from frontmatter
      desc=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^description:' | sed 's/^description: *"//' | sed 's/"$//' | head -1)
      # Take first sentence only
      short_desc=$(echo "$desc" | sed 's/\. .*/\./')
      SKILLS_BLOCK="${SKILLS_BLOCK}
| \`${skill_name}\` | ${short_desc} |"
    fi
  done

  SKILLS_BLOCK="${SKILLS_BLOCK}
${MARKER_END}"

  if [ -f "$CLAUDE_MD" ]; then
    if grep -q "$MARKER" "$CLAUDE_MD"; then
      # Replace existing block
      BLOCK_FILE="$(mktemp)"
      echo "$SKILLS_BLOCK" > "$BLOCK_FILE"
      awk '
        /<!-- claude-skills:begin -->/ { while((getline line < "'"$BLOCK_FILE"'") > 0) print line; skip=1; next }
        /<!-- claude-skills:end -->/ { skip=0; next }
        !skip { print }
      ' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp"
      rm -f "$BLOCK_FILE"
      mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
      echo -e "${GREEN}Updated skills section in existing CLAUDE.md${NC}"
    else
      echo "" >> "$CLAUDE_MD"
      echo "$SKILLS_BLOCK" >> "$CLAUDE_MD"
      echo -e "${GREEN}Appended skills section to existing CLAUDE.md${NC}"
    fi
  else
    cat > "$CLAUDE_MD" << 'HEREDOC'
# Project Instructions

<!-- Add your project-specific instructions here -->

HEREDOC
    echo "$SKILLS_BLOCK" >> "$CLAUDE_MD"
    echo -e "${GREEN}Created CLAUDE.md with skills section${NC}"
  fi
fi

echo ""
echo -e "${BOLD}Done!${NC} Skills installed in ${CYAN}${SKILLS_TARGET}${NC}"
echo -e "Run ${CYAN}claude${NC} in your project to start using them."
