#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# install-from-github.sh
# Downloads and installs Claude Code skills directly from GitHub.
# Supports cluster-based filtering, merges with existing skills,
# and patches CLAUDE.md with a cluster-grouped skills catalog.
#
# Usage:
#   ./install-from-github.sh [target-path] [options]
#   curl -sL <raw-url> | bash -s -- [target-path] [options]
#
# Options:
#   --cluster <name>   Install only this cluster (repeatable)
#   --list-clusters    Show available clusters and exit
#   --force            Overwrite existing skills
#   --no-patch         Skip CLAUDE.md patching
#   --branch <name>    GitHub branch (default: main)
#   --repo <owner/repo> GitHub repo (default: mmondora/claude-skills)
#
# Examples:
#   ./install-from-github.sh .                         # all curated skills
#   ./install-from-github.sh . --cluster security-compliance
#   ./install-from-github.sh /my/project --cluster testing-quality --cluster delivery-release
#   ./install-from-github.sh . --list-clusters
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

ALL_CLUSTERS="foundations cloud-infrastructure security-compliance testing-quality delivery-release documentation-diagrams data-architecture architecture-patterns ai-applications mobile green-software"

list_clusters() {
  echo -e "${BOLD}Available clusters:${NC}"
  echo ""
  for slug in $ALL_CLUSTERS; do
    display=$(cluster_display_name "$slug")
    printf "  ${CYAN}%-25s${NC} %s\n" "$slug" "$display"
  done
  echo ""
  echo -e "${DIM}Use: --cluster <slug> (repeatable)${NC}"
}

# ── Parse arguments ──
TARGET=""
CLUSTERS=()
FORCE=false
NO_PATCH=false
NO_AGENTS=false
BRANCH="main"
REPO="mmondora/claude-skills"
LIST_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --cluster)
      shift
      [ $# -eq 0 ] && { echo -e "${RED}Error: --cluster requires a value${NC}"; exit 1; }
      CLUSTERS+=("$1")
      ;;
    --list-clusters)
      LIST_ONLY=true
      ;;
    --force)
      FORCE=true
      ;;
    --no-patch)
      NO_PATCH=true
      ;;
    --no-agents)
      NO_AGENTS=true
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
      echo -e "${BOLD}claude-skills remote installer${NC}"
      echo ""
      echo "Downloads curated skills from GitHub and installs them into your project."
      echo "Merges with existing skills and updates CLAUDE.md."
      echo ""
      echo "Usage:"
      echo "  ./install-from-github.sh [target-path] [options]"
      echo ""
      echo "Options:"
      echo "  --cluster <slug>     Install only this cluster (repeatable)"
      echo "  --list-clusters      Show available clusters and exit"
      echo "  --force              Overwrite existing skills without prompting"
      echo "  --no-patch           Skip CLAUDE.md patching"
      echo "  --no-agents          Skip AGENTS.md installation"
      echo "  --branch <name>      GitHub branch (default: main)"
      echo "  --repo <owner/repo>  GitHub repo (default: mmondora/claude-skills)"
      echo ""
      echo "Examples:"
      echo "  ./install-from-github.sh .                                    # all curated"
      echo "  ./install-from-github.sh . --cluster security-compliance      # one cluster"
      echo "  ./install-from-github.sh . --cluster testing-quality --cluster delivery-release"
      echo "  ./install-from-github.sh . --list-clusters"
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

# ── List clusters and exit ──
if [ "$LIST_ONLY" = true ]; then
  list_clusters
  exit 0
fi

# ── Validate target ──
if [ -z "$TARGET" ]; then
  TARGET="."
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  echo -e "${RED}Error: directory '$TARGET' does not exist${NC}"
  exit 1
}

# ── Validate requested clusters ──
for c in "${CLUSTERS[@]+"${CLUSTERS[@]}"}"; do
  display=$(cluster_display_name "$c")
  if [ -z "$display" ]; then
    echo -e "${RED}Error: unknown cluster '$c'${NC}"
    echo ""
    list_clusters
    exit 1
  fi
done

# ── Header ──
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

echo -e "${BOLD}claude-skills remote installer${NC}"
echo -e "${CYAN}Source:${NC} ${REPO} @ ${BRANCH}"
echo -e "${CYAN}Target:${NC} ${TARGET}"
if [ ${#CLUSTERS[@]} -gt 0 ]; then
  cluster_list=""
  for c in "${CLUSTERS[@]}"; do
    display=$(cluster_display_name "$c")
    cluster_list="${cluster_list:+$cluster_list, }$c ($display)"
  done
  echo -e "${CYAN}Clusters:${NC} ${cluster_list}"
else
  echo -e "${CYAN}Clusters:${NC} all"
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
echo -e "${CYAN}Scanning skills...${NC}"

# Collect curated skills: skill_name → cluster
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
echo -e "  Found ${BOLD}${total_curated}${NC} curated skills"

# ── Filter by cluster if requested ──
if [ ${#CLUSTERS[@]} -gt 0 ]; then
  tmpfiltered=$(mktemp)
  for c in "${CLUSTERS[@]}"; do
    grep "	${c}$" "$tmpmap" >> "$tmpfiltered" || true
  done
  mv "$tmpfiltered" "$tmpmap"

  filtered_count=$(wc -l < "$tmpmap" | tr -d ' ')
  echo -e "  Filtered to ${BOLD}${filtered_count}${NC} skills in requested cluster(s)"

  if [ "$filtered_count" -eq 0 ]; then
    echo -e "${YELLOW}No skills matched the requested cluster(s). Nothing to install.${NC}"
    exit 0
  fi
fi

# ── Check existing skills ──
SKILLS_TARGET="${TARGET}/.claude/skills"
mkdir -p "$SKILLS_TARGET"

if [ -d "$SKILLS_TARGET" ] && [ "$FORCE" = false ]; then
  existing_count=0
  while IFS=$'\t' read -r skill_name _cluster; do
    [ -d "${SKILLS_TARGET}/${skill_name}" ] && existing_count=$((existing_count + 1))
  done < "$tmpmap"

  if [ "$existing_count" -gt 0 ]; then
    echo -e "  ${YELLOW}${existing_count} skill(s) already exist — will be merged (use --force to overwrite)${NC}"
  fi
fi

# ── Install skills ──
echo ""
echo -e "${CYAN}Installing skills...${NC}"

INSTALLED=0
UPDATED=0

while IFS=$'\t' read -r skill_name cluster; do
  src="${EXTRACTED_SKILLS}/${skill_name}"
  dst="${SKILLS_TARGET}/${skill_name}"

  if [ -d "$dst" ]; then
    if [ "$FORCE" = true ]; then
      rm -rf "$dst"
      cp -r "$src" "$dst"
      echo -e "  ${GREEN}[updated]${NC}  ${skill_name} ${DIM}(${cluster})${NC}"
    else
      # Merge: copy files, overwrite existing
      cp -r "${src}"/* "$dst/"
      echo -e "  ${GREEN}[merged]${NC}   ${skill_name} ${DIM}(${cluster})${NC}"
    fi
    UPDATED=$((UPDATED + 1))
  else
    cp -r "$src" "$dst"
    echo -e "  ${GREEN}[new]${NC}      ${skill_name} ${DIM}(${cluster})${NC}"
    INSTALLED=$((INSTALLED + 1))
  fi
done < "$tmpmap"

rm -f "$tmpmap"

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

# ── Install AGENTS.md ──
if [ "$NO_AGENTS" = false ]; then
  AGENTS_SRC="${EXTRACTED}/AGENTS.md"
  AGENTS_DST="${TARGET}/AGENTS.md"

  if [ -f "$AGENTS_SRC" ]; then
    echo ""
    echo -e "${CYAN}Installing AGENTS.md...${NC}"
    if [ -f "$AGENTS_DST" ]; then
      if [ "$FORCE" = true ]; then
        cp "$AGENTS_SRC" "$AGENTS_DST"
        echo -e "  ${GREEN}[updated]${NC}  AGENTS.md"
      else
        echo -e "  ${DIM}[exists]${NC}   AGENTS.md ${DIM}(use --force to overwrite)${NC}"
      fi
    else
      cp "$AGENTS_SRC" "$AGENTS_DST"
      echo -e "  ${GREEN}[new]${NC}      AGENTS.md"
    fi

    # Append agent config block to target CLAUDE.md if not present
    if [ "$NO_PATCH" = false ] && [ -f "$CLAUDE_MD" ]; then
      AGENT_MARKER="<!-- claude-agents:begin -->"
      if ! grep -q "$AGENT_MARKER" "$CLAUDE_MD"; then
        SKILLS_MARKER="<!-- claude-skills:begin -->"
        AGENT_BLOCK='<!-- claude-agents:begin -->
## Active Agents

All agents are enabled by default. Customize by editing the values below.

agents:
  po: true
  architect: true
  engman: true
  dev: true

For full agent profiles and collaboration protocol, see `AGENTS.md`.
<!-- claude-agents:end -->'
        if grep -q "$SKILLS_MARKER" "$CLAUDE_MD"; then
          # Insert before skills marker
          AGENT_FILE="$(mktemp)"
          echo "$AGENT_BLOCK" > "$AGENT_FILE"
          awk -v af="$AGENT_FILE" '
            /<!-- claude-skills:begin -->/ {
              while((getline line < af) > 0) print line
              close(af)
              print ""
            }
            { print }
          ' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp"
          rm -f "$AGENT_FILE"
          mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
        else
          echo "" >> "$CLAUDE_MD"
          echo "$AGENT_BLOCK" >> "$CLAUDE_MD"
        fi
        echo -e "  ${GREEN}Added agent configuration to CLAUDE.md${NC}"
      fi
    fi
  fi
fi

# ── Done ──
echo ""
echo -e "${BOLD}Done!${NC} Skills installed in ${CYAN}${SKILLS_TARGET}${NC}"
echo -e "Run ${CYAN}claude${NC} in your project to start using them."
