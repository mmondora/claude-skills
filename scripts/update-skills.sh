#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# update-skills.sh
# Updates locally installed Claude Code skills to the latest
# versions from GitHub. Compares local vs remote content,
# installs missing skills, updates changed ones, skips identical
# ones, and patches CLAUDE.md with the updated skills catalog.
#
# Usage:
#   ./scripts/update-skills.sh [target-path] [options]
#
# Options:
#   --dry-run          Show what would change without applying
#   --no-patch         Skip CLAUDE.md patching
#   --branch <name>    GitHub branch (default: main)
#   --repo <owner/repo> GitHub repo (default: mmondora/claude-skills)
#
# Examples:
#   ./scripts/update-skills.sh .                     # update all curated skills
#   ./scripts/update-skills.sh . --dry-run           # preview changes
#   ./scripts/update-skills.sh . --branch develop    # update from a branch
# ─────────────────────────────────────────────────────────────

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Cluster functions (bash 3.2 compatible — case statements) ──
cluster_display_name() {
  case "$1" in
    foundations)              echo "Foundations" ;;
    cloud-infrastructure)    echo "Cloud & Infrastructure" ;;
    security-compliance)     echo "Security & Compliance" ;;
    testing-quality)         echo "Testing & Quality" ;;
    delivery-release)        echo "Delivery & Release" ;;
    documentation-diagrams)  echo "Documentation & Diagrams" ;;
    data-architecture)       echo "Data Architecture" ;;
    architecture-patterns)   echo "Architecture & Patterns" ;;
    ai-applications)         echo "AI & Applications" ;;
    mobile)                  echo "Mobile & Native" ;;
    green-software)          echo "Green Software & Sustainability" ;;
    *)                       echo "" ;;
  esac
}

cluster_sort_order() {
  case "$1" in
    foundations)              echo "01" ;;
    cloud-infrastructure)    echo "02" ;;
    security-compliance)     echo "03" ;;
    testing-quality)         echo "04" ;;
    delivery-release)        echo "05" ;;
    documentation-diagrams)  echo "06" ;;
    data-architecture)       echo "07" ;;
    architecture-patterns)   echo "08" ;;
    ai-applications)         echo "09" ;;
    mobile)                  echo "10" ;;
    green-software)          echo "11" ;;
    *)                       echo "99" ;;
  esac
}

# ── Parse arguments ──
TARGET=""
DRY_RUN=false
NO_PATCH=false
BRANCH="main"
REPO="mmondora/claude-skills"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --no-patch)
      NO_PATCH=true
      ;;
    --branch)
      shift
      [ $# -eq 0 ] && { echo -e "${RED}Error: --branch requires a value${NC}"; exit 1; }
      BRANCH="$1"
      ;;
    --repo)
      shift
      [ $# -eq 0 ] && { echo -e "${RED}Error: --repo requires a value${NC}"; exit 1; }
      REPO="$1"
      ;;
    --help|-h)
      echo -e "${BOLD}claude-skills updater${NC}"
      echo ""
      echo "Updates locally installed curated skills to the latest versions from GitHub."
      echo "Compares local vs remote content, installs missing, updates changed, skips identical."
      echo ""
      echo "Usage:"
      echo "  ./scripts/update-skills.sh [target-path] [options]"
      echo ""
      echo "Options:"
      echo "  --dry-run            Show what would change without applying"
      echo "  --no-patch           Skip CLAUDE.md patching"
      echo "  --branch <name>      GitHub branch (default: main)"
      echo "  --repo <owner/repo>  GitHub repo (default: mmondora/claude-skills)"
      echo ""
      echo "Examples:"
      echo "  ./scripts/update-skills.sh .                     # update all curated skills"
      echo "  ./scripts/update-skills.sh . --dry-run           # preview changes"
      echo "  ./scripts/update-skills.sh . --branch develop    # update from a branch"
      exit 0
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        echo -e "${RED}Error: unexpected argument '$1'${NC}"
        exit 1
      fi
      ;;
  esac
  shift
done

# ── Validate target ──
if [ -z "$TARGET" ]; then
  TARGET="."
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  echo -e "${RED}Error: directory '$TARGET' does not exist${NC}"
  exit 1
}

SKILLS_TARGET="${TARGET}/.claude/skills"
FRESH_INSTALL=false

if [ ! -d "$SKILLS_TARGET" ]; then
  FRESH_INSTALL=true
fi

# ── Header ──
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

echo -e "${BOLD}claude-skills updater${NC}"
echo -e "${CYAN}Source:${NC} ${REPO} @ ${BRANCH}"
echo -e "${CYAN}Target:${NC} ${TARGET}"
if [ "$FRESH_INSTALL" = true ]; then
  echo -e "${YELLOW}No existing skills found — will perform fresh install${NC}"
fi
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Dry run — no changes will be made${NC}"
fi
echo ""

# ── Check dependencies ──
if ! command -v curl &> /dev/null; then
  echo -e "${RED}Error: curl is required but not found${NC}"
  exit 1
fi

# ── Download and extract ──
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "${CYAN}Downloading from GitHub...${NC}"
HTTP_CODE=$(curl -sL -w '%{http_code}' -o "${TMPDIR}/repo.tar.gz" "$TARBALL_URL")

if [ "$HTTP_CODE" != "200" ]; then
  echo -e "${RED}Error: download failed (HTTP ${HTTP_CODE})${NC}"
  echo -e "${RED}URL: ${TARBALL_URL}${NC}"
  exit 1
fi

echo -e "${CYAN}Extracting...${NC}"
tar xzf "${TMPDIR}/repo.tar.gz" -C "$TMPDIR"

# Find the extracted directory (github names it <repo>-<branch>/)
EXTRACTED="$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d | head -1)"
EXTRACTED_SKILLS="${EXTRACTED}/.claude/skills"

if [ ! -d "$EXTRACTED_SKILLS" ]; then
  echo -e "${RED}Error: no .claude/skills/ found in downloaded archive${NC}"
  exit 1
fi

# ── Identify curated skills (those with cluster: in frontmatter) ──
echo -e "${CYAN}Scanning remote skills...${NC}"

tmpmap=$(mktemp)
for skill_dir in "$EXTRACTED_SKILLS"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_file="${skill_dir}SKILL.md"
  [ -f "$skill_file" ] || continue

  skill_name=$(basename "$skill_dir")
  cluster=$(grep '^cluster:' "$skill_file" 2>/dev/null | head -1 | sed 's/^cluster: *//' || true)

  # Only curated skills have a cluster field
  [ -z "$cluster" ] && continue

  printf '%s\t%s\n' "$skill_name" "$cluster" >> "$tmpmap"
done

total_curated=$(wc -l < "$tmpmap" | tr -d ' ')
echo -e "  Found ${BOLD}${total_curated}${NC} curated skills in remote"

# ── Compare local vs remote ──
echo -e "${CYAN}Comparing skills...${NC}"
echo ""

NEW_SKILLS=()
UPDATED_SKILLS=()
CURRENT_SKILLS=()

while IFS=$'\t' read -r skill_name cluster; do
  src="${EXTRACTED_SKILLS}/${skill_name}"
  dst="${SKILLS_TARGET}/${skill_name}"

  if [ ! -d "$dst" ]; then
    # Skill doesn't exist locally
    NEW_SKILLS+=("${skill_name}")
    echo -e "  ${GREEN}[new]${NC}      ${skill_name} ${DIM}(${cluster})${NC}"
  else
    # Skill exists — compare SKILL.md content
    src_file="${src}/SKILL.md"
    dst_file="${dst}/SKILL.md"

    if [ ! -f "$dst_file" ]; then
      # Local dir exists but no SKILL.md — treat as new
      UPDATED_SKILLS+=("${skill_name}")
      echo -e "  ${YELLOW}[updated]${NC}  ${skill_name} ${DIM}(${cluster})${NC}"
    elif diff -q "$src_file" "$dst_file" > /dev/null 2>&1; then
      # Content is identical
      CURRENT_SKILLS+=("${skill_name}")
      echo -e "  ${DIM}[current]  ${skill_name} (${cluster})${NC}"
    else
      # Content differs
      UPDATED_SKILLS+=("${skill_name}")
      echo -e "  ${YELLOW}[updated]${NC}  ${skill_name} ${DIM}(${cluster})${NC}"
    fi
  fi
done < "$tmpmap"

echo ""
echo -e "${BOLD}Summary:${NC} ${GREEN}${#NEW_SKILLS[@]} new${NC}  |  ${YELLOW}${#UPDATED_SKILLS[@]} updated${NC}  |  ${DIM}${#CURRENT_SKILLS[@]} current${NC}"

# ── Dry run exits here ──
if [ "$DRY_RUN" = true ]; then
  echo ""
  if [ ${#NEW_SKILLS[@]} -eq 0 ] && [ ${#UPDATED_SKILLS[@]} -eq 0 ]; then
    echo -e "${GREEN}All skills are up to date.${NC}"
  else
    echo -e "${CYAN}Run without --dry-run to apply changes.${NC}"
  fi
  exit 0
fi

# ── Nothing to do ──
if [ ${#NEW_SKILLS[@]} -eq 0 ] && [ ${#UPDATED_SKILLS[@]} -eq 0 ]; then
  echo ""
  echo -e "${GREEN}All skills are up to date. Nothing to do.${NC}"
  exit 0
fi

# ── Apply changes ──
echo ""
echo -e "${CYAN}Applying changes...${NC}"

mkdir -p "$SKILLS_TARGET"

# Install new skills
for skill_name in "${NEW_SKILLS[@]+"${NEW_SKILLS[@]}"}"; do
  [ -z "$skill_name" ] && continue
  src="${EXTRACTED_SKILLS}/${skill_name}"
  dst="${SKILLS_TARGET}/${skill_name}"
  cp -r "$src" "$dst"
done

# Update changed skills
for skill_name in "${UPDATED_SKILLS[@]+"${UPDATED_SKILLS[@]}"}"; do
  [ -z "$skill_name" ] && continue
  src="${EXTRACTED_SKILLS}/${skill_name}"
  dst="${SKILLS_TARGET}/${skill_name}"
  rm -rf "$dst"
  cp -r "$src" "$dst"
done

rm -f "$tmpmap"

echo -e "  ${GREEN}Applied ${#NEW_SKILLS[@]} new + ${#UPDATED_SKILLS[@]} updated skills${NC}"

# ── Patch CLAUDE.md ──
if [ "$NO_PATCH" = true ]; then
  echo ""
  echo -e "${CYAN}Skipping CLAUDE.md patch (--no-patch)${NC}"
else
  CLAUDE_MD="${TARGET}/CLAUDE.md"
  MARKER="<!-- claude-skills:begin -->"
  MARKER_END="<!-- claude-skills:end -->"

  echo ""
  echo -e "${CYAN}Updating CLAUDE.md...${NC}"

  # Scan ALL skills in target (not just newly installed) to build full catalog
  tmpskills=$(mktemp)
  for skill_dir in "$SKILLS_TARGET"/*/; do
    skill_name="$(basename "$skill_dir")"
    [[ "$skill_name" == .* ]] && continue

    skill_file="${skill_dir}SKILL.md"
    [ -f "$skill_file" ] || continue

    # Extract cluster and description from frontmatter
    cluster=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^cluster:' | sed 's/^cluster: *//' | head -1 || true)
    desc=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^description:' | sed 's/^description: *"//' | sed 's/"$//' | head -1 || true)
    short_desc=$(echo "$desc" | sed 's/\. .*/\./')

    if [ -n "$cluster" ]; then
      sort_order=$(cluster_sort_order "$cluster")
      display=$(cluster_display_name "$cluster")
      if [ -n "$display" ]; then
        printf '%s\t%s\t%s\t%s\n' "$sort_order" "$display" "$skill_name" "$short_desc" >> "$tmpskills"
        continue
      fi
    fi
    # Unclustered skills
    printf '%s\t%s\t%s\t%s\n' "99" "__unclustered__" "$skill_name" "$short_desc" >> "$tmpskills"
  done

  # Sort by cluster order, then skill name
  sort -t$'\t' -k1,1 -k3,3 "$tmpskills" > "${tmpskills}.sorted"

  # Build skills block
  SKILLS_BLOCK="${MARKER}
## Installed Skills

The following Claude Code skills are installed in \`.claude/skills/\`. Claude will auto-load them based on context, or you can invoke them with \`/<skill-name>\`."

  current_cluster=""
  unclustered_skills=""
  while IFS=$'\t' read -r _order cluster skill desc; do
    # Skip blank lines
    [ -z "$skill" ] && continue
    if [ "$cluster" = "__unclustered__" ]; then
      unclustered_skills="${unclustered_skills}
| \`${skill}\` | ${desc} |"
      continue
    fi
    if [ "$cluster" != "$current_cluster" ]; then
      SKILLS_BLOCK="${SKILLS_BLOCK}

### ${cluster}
| Skill | Description |
|-------|-------------|"
      current_cluster="$cluster"
    fi
    SKILLS_BLOCK="${SKILLS_BLOCK}
| \`${skill}\` | ${desc} |"
  done < "${tmpskills}.sorted"

  # Append unclustered skills if any
  if [ -n "$unclustered_skills" ]; then
    SKILLS_BLOCK="${SKILLS_BLOCK}

### Other Skills
| Skill | Description |
|-------|-------------|${unclustered_skills}"
  fi

  rm -f "$tmpskills" "${tmpskills}.sorted"

  SKILLS_BLOCK="${SKILLS_BLOCK}
${MARKER_END}"

  # Apply to CLAUDE.md
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
      echo -e "  ${GREEN}Updated skills section in existing CLAUDE.md${NC}"
    else
      echo "" >> "$CLAUDE_MD"
      echo "$SKILLS_BLOCK" >> "$CLAUDE_MD"
      echo -e "  ${GREEN}Appended skills section to CLAUDE.md${NC}"
    fi
  else
    cat > "$CLAUDE_MD" << 'HEREDOC'
# Project Instructions

<!-- Add your project-specific instructions here -->

HEREDOC
    echo "$SKILLS_BLOCK" >> "$CLAUDE_MD"
    echo -e "  ${GREEN}Created CLAUDE.md with skills section${NC}"
  fi
fi

# ── Done ──
echo ""
echo -e "${BOLD}Done!${NC} Skills updated in ${CYAN}${SKILLS_TARGET}${NC}"
echo -e "Run ${CYAN}claude${NC} in your project to start using them."
