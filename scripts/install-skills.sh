#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# install-skills.sh
# Installs Claude Code skills into a target project.
# Unpacks skills from scripts/claude-skills-<version>.zip into <target>/.claude/skills/,
# patches/creates CLAUDE.md with skill references, sets up a
# pre-commit hook that auto-updates README.md with the skills catalog.
#
# Usage:
#   ./scripts/install-skills.sh <target-project-path> [--no-patch] [--no-hooks] [--force]
#
# Options:
#   --no-patch   Skip CLAUDE.md patching
#   --no-hooks   Skip pre-commit hook and README.md setup
#   --force      Overwrite existing skills without prompting
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Find the latest versioned zip in scripts/
SKILLS_ZIP="$(ls -t "${SCRIPT_DIR}"/claude-skills-*.zip 2>/dev/null | head -1 || true)"
if [ -z "$SKILLS_ZIP" ]; then
  echo -e "${RED}Error: no claude-skills-*.zip found in scripts/${NC}"
  echo "Run ./scripts/build-zip.sh first."
  exit 1
fi

# ── Parse arguments ──
TARGET=""
NO_PATCH=false
NO_HOOKS=false
FORCE=false
INCLUDE_COMMUNITY=false

for arg in "$@"; do
  case "$arg" in
    --no-patch) NO_PATCH=true ;;
    --no-hooks) NO_HOOKS=true ;;
    --force) FORCE=true ;;
    --include-community) INCLUDE_COMMUNITY=true ;;
    --help|-h)
      echo -e "${BOLD}claude-skills installer${NC}"
      echo ""
      echo "Usage: ./scripts/install-skills.sh <target-project-path> [--no-patch] [--no-hooks] [--force] [--include-community]"
      echo ""
      echo "Options:"
      echo "  --no-patch            Skip CLAUDE.md patching"
      echo "  --no-hooks            Skip pre-commit hook and README.md setup"
      echo "  --force               Overwrite existing skills without prompting"
      echo "  --include-community   Also install community skills from community/skills/"
      echo ""
      echo "This script unpacks Claude Code skills from scripts/claude-skills-<version>.zip"
      echo "into <target>/.claude/skills/, patches CLAUDE.md, and sets up"
      echo "a pre-commit hook that auto-updates README.md with the skills catalog."
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

ZIP_VERSION=$(basename "$SKILLS_ZIP" | sed 's/claude-skills-//;s/\.zip//')
echo -e "${BOLD}claude-skills installer${NC} ${CYAN}v${ZIP_VERSION}${NC}"
echo -e "${CYAN}Target:${NC} $TARGET"
echo ""

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

  # Cluster slug → display name (bash 3.2 compatible)
  cluster_display_name() {
    case "$1" in
      foundations)              echo "Foundations" ;;
      cloud-infrastructure)    echo "Cloud & Infrastructure" ;;
      security-compliance)     echo "Security & Compliance" ;;
      testing-quality)         echo "Testing & Quality" ;;
      delivery-release)        echo "Delivery & Release" ;;
      documentation-diagrams)  echo "Documentation & Diagrams" ;;
      data-architecture)       echo "Data Architecture" ;;
      api-integration)         echo "API & Integration" ;;
      *)                       echo "" ;;
    esac
  }

  # Cluster slug → sort order
  cluster_sort_order() {
    case "$1" in
      foundations)              echo "01" ;;
      cloud-infrastructure)    echo "02" ;;
      security-compliance)     echo "03" ;;
      testing-quality)         echo "04" ;;
      delivery-release)        echo "05" ;;
      documentation-diagrams)  echo "06" ;;
      data-architecture)       echo "07" ;;
      api-integration)         echo "08" ;;
      *)                       echo "99" ;;
    esac
  }

  # Collect skill data with cluster info
  tmpskills=$(mktemp)
  for skill_dir in "$SKILLS_TARGET"/*/; do
    skill_name="$(basename "$skill_dir")"
    [[ "$skill_name" == .* ]] && continue

    skill_file="${skill_dir}SKILL.md"
    if [ -f "$skill_file" ]; then
      # Extract cluster and description from frontmatter
      cluster=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^cluster:' | sed 's/^cluster: *//' | head -1)
      desc=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^description:' | sed 's/^description: *"//' | sed 's/"$//' | head -1)
      short_desc=$(echo "$desc" | sed 's/\. .*/\./')

      if [ -n "$cluster" ]; then
        sort_order=$(cluster_sort_order "$cluster")
        display=$(cluster_display_name "$cluster")
        if [ -n "$display" ]; then
          printf '%s\t%s\t%s\t%s\n' "$sort_order" "$display" "$skill_name" "$short_desc" >> "$tmpskills"
          continue
        fi
      fi
      # Unclustered skills go to a flat section
      printf '%s\t%s\t%s\t%s\n' "99" "__unclustered__" "$skill_name" "$short_desc" >> "$tmpskills"
    fi
  done

  # Sort by cluster order, then skill name
  sort -t$'\t' -k1,1 -k3,3 "$tmpskills" > "${tmpskills}.sorted"

  # Build the skills reference block grouped by cluster
  SKILLS_BLOCK="${MARKER}
## Installed Skills

The following Claude Code skills are installed in \`.claude/skills/\`. Claude will auto-load them based on context, or you can invoke them with \`/<skill-name>\`."

  current_cluster=""
  unclustered_skills=""
  while IFS=$'\t' read -r _order cluster skill desc; do
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

# ── Install pre-commit hook + generate-readme.sh ──
if [ "$NO_HOOKS" = true ]; then
  echo ""
  echo -e "${CYAN}Skipping hooks and README setup (--no-hooks)${NC}"
else
  # Check if target is a git repo
  if ! git -C "$TARGET" rev-parse --git-dir > /dev/null 2>&1; then
    echo ""
    echo -e "${YELLOW}Target is not a git repository — skipping hooks setup${NC}"
  else
    echo ""
    echo -e "${CYAN}Setting up auto-README...${NC}"

    # ── Copy generate-readme.sh ──
    mkdir -p "${TARGET}/scripts"
    cp "${REPO_ROOT}/scripts/generate-readme.sh" "${TARGET}/scripts/generate-readme.sh"
    chmod +x "${TARGET}/scripts/generate-readme.sh"
    echo -e "  ${GREEN}[installed]${NC} scripts/generate-readme.sh"

    # ── Set up pre-commit hook ──
    HOOKS_DIR="${TARGET}/.githooks"
    HOOK_FILE="${HOOKS_DIR}/pre-commit"
    HOOK_MARKER="# claude-skills:generate-readme"

    mkdir -p "$HOOKS_DIR"

    if [ -f "$HOOK_FILE" ]; then
      if grep -q "$HOOK_MARKER" "$HOOK_FILE"; then
        echo -e "  ${GREEN}[exists]${NC}    .githooks/pre-commit (already configured)"
      else
        # Append to existing hook
        cat >> "$HOOK_FILE" << 'HOOKEOF'

# claude-skills:generate-readme
REPO_ROOT="$(git rev-parse --show-toplevel)"
if git diff --cached --name-only | grep -qE '(\.claude/skills/|README\.md)' \
   || ! grep -q '<!-- SKILLS_START -->' "$REPO_ROOT/README.md" 2>/dev/null; then
  "$REPO_ROOT/scripts/generate-readme.sh"
  git add "$REPO_ROOT/README.md"
fi
HOOKEOF
        echo -e "  ${GREEN}[appended]${NC}  .githooks/pre-commit"
      fi
    else
      cat > "$HOOK_FILE" << 'HOOKEOF'
#!/usr/bin/env bash
set -euo pipefail

# claude-skills:generate-readme
REPO_ROOT="$(git rev-parse --show-toplevel)"
if git diff --cached --name-only | grep -qE '(\.claude/skills/|README\.md)' \
   || ! grep -q '<!-- SKILLS_START -->' "$REPO_ROOT/README.md" 2>/dev/null; then
  "$REPO_ROOT/scripts/generate-readme.sh"
  git add "$REPO_ROOT/README.md"
fi
HOOKEOF
      echo -e "  ${GREEN}[created]${NC}   .githooks/pre-commit"
    fi
    chmod +x "$HOOK_FILE"

    # ── Configure git hooks path ──
    git -C "$TARGET" config core.hooksPath .githooks
    echo -e "  ${GREEN}[configured]${NC} git core.hooksPath → .githooks"

    # ── Ensure README.md has markers ──
    TARGET_README="${TARGET}/README.md"
    if [ ! -f "$TARGET_README" ]; then
      # Create README with markers
      PROJECT_NAME="$(basename "$TARGET")"
      cat > "$TARGET_README" << READMEEOF
# ${PROJECT_NAME}

## Skills Catalog

<!-- SKILLS_START -->
<!-- SKILLS_END -->
READMEEOF
      echo -e "  ${GREEN}[created]${NC}   README.md"
    elif ! grep -q '<!-- SKILLS_START -->' "$TARGET_README"; then
      # Append skills section with markers
      cat >> "$TARGET_README" << 'READMEEOF'

## Skills Catalog

<!-- SKILLS_START -->
<!-- SKILLS_END -->
READMEEOF
      echo -e "  ${GREEN}[patched]${NC}   README.md (added skills catalog section)"
    fi

    # ── Run generate-readme.sh to populate catalog ──
    if [ -f "${TARGET}/scripts/generate-readme.sh" ] && grep -q '<!-- SKILLS_START -->' "$TARGET_README" 2>/dev/null; then
      "${TARGET}/scripts/generate-readme.sh" > /dev/null 2>&1 && \
        echo -e "  ${GREEN}[generated]${NC} README.md skills catalog" || \
        echo -e "  ${YELLOW}[warning]${NC}   Could not auto-generate README catalog"
    fi
  fi
fi

# ── Install community skills ──
if [ "$INCLUDE_COMMUNITY" = true ]; then
  COMMUNITY_DIR="${REPO_ROOT}/community/skills"
  if [ -d "$COMMUNITY_DIR" ]; then
    echo ""
    echo -e "${CYAN}Installing community skills...${NC}"
    COMMUNITY_INSTALLED=0
    for source_dir in "$COMMUNITY_DIR"/*/; do
      [ -d "$source_dir" ] || continue
      source_name="$(basename "$source_dir")"
      for skill_dir in "$source_dir"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        [[ "$skill_name" == .* ]] && continue
        skill_target="${SKILLS_TARGET}/${skill_name}"
        if [ -d "$skill_target" ] && [ "$FORCE" = false ]; then
          continue  # Skip existing skills
        fi
        cp -r "${source_dir}/${skill_name}" "${SKILLS_TARGET}/"
        COMMUNITY_INSTALLED=$((COMMUNITY_INSTALLED + 1))
      done
      # Also install single-skill sources (SKILL.md directly in source_dir)
      if [ -f "${source_dir}/SKILL.md" ] && [ ! -d "${SKILLS_TARGET}/${source_name}" ]; then
        mkdir -p "${SKILLS_TARGET}/${source_name}"
        cp -r "${source_dir}"/* "${SKILLS_TARGET}/${source_name}/"
        COMMUNITY_INSTALLED=$((COMMUNITY_INSTALLED + 1))
      fi
    done
    echo -e "${GREEN}Installed ${COMMUNITY_INSTALLED} community skills${NC}"
  else
    echo -e "${YELLOW}No community skills found. Run community/download-community.sh first.${NC}"
  fi
fi

echo ""
echo -e "${BOLD}Done!${NC} Skills installed in ${CYAN}${SKILLS_TARGET}${NC}"
echo -e "Run ${CYAN}claude${NC} in your project to start using them."
