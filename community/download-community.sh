#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# download-community.sh
# Clones community skill repositories and extracts skills,
# hooks, and tools into the community/ directory.
#
# Usage:
#   ./community/download-community.sh [--clean]
#
# Options:
#   --clean   Remove existing community content before downloading
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$SCRIPT_DIR"
SKILLS_DIR="${COMMUNITY_DIR}/skills"
HOOKS_DIR="${COMMUNITY_DIR}/hooks"
TOOLS_DIR="${COMMUNITY_DIR}/tools"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Parse arguments ──
CLEAN=false
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=true ;;
    --help|-h)
      echo -e "${BOLD}community skill downloader${NC}"
      echo ""
      echo "Usage: ./community/download-community.sh [--clean]"
      echo ""
      echo "Options:"
      echo "  --clean   Remove existing community content before downloading"
      exit 0
      ;;
    *)
      echo -e "${RED}Error: unexpected argument '$arg'${NC}"
      exit 1
      ;;
  esac
done

# ── Clean if requested ──
if [ "$CLEAN" = true ]; then
  echo -e "${YELLOW}Cleaning existing community skills...${NC}"
  rm -rf "${SKILLS_DIR:?}"/*
  rm -rf "${HOOKS_DIR:?}"/johnlindquist-claude-hooks
  rm -rf "${HOOKS_DIR:?}"/claude-code-discord
  rm -rf "${TOOLS_DIR:?}"/skill-seekers
fi

# ── Temp directory ──
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "${BOLD}Community Skills Downloader${NC}"
echo -e "${CYAN}Temp directory:${NC} $TMPDIR"
echo ""

# ── Helper: clone a repo ──
clone_repo() {
  local repo="$1"
  local dest="$2"
  echo -e "  ${CYAN}Cloning${NC} ${repo}..."
  git clone --depth 1 --quiet "https://github.com/${repo}.git" "$dest" 2>/dev/null || {
    echo -e "  ${YELLOW}[warning]${NC} Failed to clone ${repo} — skipping"
    return 1
  }
}

# ── Helper: copy skill subdirectories from a source dir to target ──
# Iterates over each subdirectory in $1 and copies it as a subdirectory of $2
copy_skill_dirs() {
  local source_dir="$1"
  local target_dir="$2"
  for d in "${source_dir}"/*/; do
    [ -d "$d" ] || continue
    local dname
    dname="$(basename "$d")"
    [[ "$dname" == .* ]] && continue
    # Use cp without trailing slash on source to preserve directory name
    cp -r "${source_dir}/${dname}" "${target_dir}/"
  done
}

TOTAL_SKILLS=0

# ─────────────────────────────────────────────────────────────
# 1. obra/superpowers — skills/ directory with subdirectories
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/23] obra/superpowers${NC}"
TARGET="${SKILLS_DIR}/obra-superpowers"
mkdir -p "$TARGET"
if clone_repo "obra/superpowers" "${TMPDIR}/superpowers"; then
  if [ -d "${TMPDIR}/superpowers/skills" ]; then
    copy_skill_dirs "${TMPDIR}/superpowers/skills" "$TARGET"
  fi
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 2. obra/superpowers-lab — skills/ directory
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/23] obra/superpowers-lab${NC}"
TARGET="${SKILLS_DIR}/obra-superpowers-lab"
mkdir -p "$TARGET"
if clone_repo "obra/superpowers-lab" "${TMPDIR}/superpowers-lab"; then
  if [ -d "${TMPDIR}/superpowers-lab/skills" ]; then
    copy_skill_dirs "${TMPDIR}/superpowers-lab/skills" "$TARGET"
  fi
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 3. anthropics/skills — skills/ directory
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[3/23] anthropics/skills${NC}"
TARGET="${SKILLS_DIR}/anthropic-official"
mkdir -p "$TARGET"
if clone_repo "anthropics/skills" "${TMPDIR}/anthropics-skills"; then
  if [ -d "${TMPDIR}/anthropics-skills/skills" ]; then
    copy_skill_dirs "${TMPDIR}/anthropics-skills/skills" "$TARGET"
  else
    # Skills might be at top level as directories with SKILL.md
    for d in "${TMPDIR}/anthropics-skills"/*/; do
      [ -d "$d" ] || continue
      dname="$(basename "$d")"
      [[ "$dname" == .* || "$dname" == "node_modules" || "$dname" == "scripts" ]] && continue
      if [ -f "${d}SKILL.md" ] || [ -f "${d}skill.md" ]; then
        cp -r "${TMPDIR}/anthropics-skills/${dname}" "${TARGET}/"
      fi
    done
  fi
  n=$(find "$TARGET" -name "SKILL.md" -o -name "skill.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 4. trailofbits/skills — plugins/*/skills/*/ (nested structure)
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[4/23] trailofbits/skills${NC}"
TARGET="${SKILLS_DIR}/trailofbits"
mkdir -p "$TARGET"
if clone_repo "trailofbits/skills" "${TMPDIR}/trailofbits-skills"; then
  # Flatten from plugins/*/skills/<skill-name>/ into trailofbits/<skill-name>/
  find "${TMPDIR}/trailofbits-skills" -name "SKILL.md" -not -path "*/.git/*" 2>/dev/null | while read -r skill_file; do
    skill_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$skill_dir")"
    # Avoid copying the repo root
    [ "$skill_name" = "trailofbits-skills" ] && continue
    mkdir -p "${TARGET}/${skill_name}"
    cp -r "${skill_dir}"/* "${TARGET}/${skill_name}/" 2>/dev/null || true
  done
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 5. jeffallan/claude-skills — skills/ directory
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[5/23] jeffallan/claude-skills${NC}"
TARGET="${SKILLS_DIR}/jeffallan"
mkdir -p "$TARGET"
if clone_repo "jeffallan/claude-skills" "${TMPDIR}/jeffallan-skills"; then
  if [ -d "${TMPDIR}/jeffallan-skills/skills" ]; then
    copy_skill_dirs "${TMPDIR}/jeffallan-skills/skills" "$TARGET"
  fi
  if [ -d "${TMPDIR}/jeffallan-skills/.claude/skills" ]; then
    copy_skill_dirs "${TMPDIR}/jeffallan-skills/.claude/skills" "$TARGET"
  fi
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 6. K-Dense-AI/claude-scientific-skills — scientific-skills/
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[6/23] K-Dense-AI/claude-scientific-skills${NC}"
TARGET="${SKILLS_DIR}/k-dense-scientific"
mkdir -p "$TARGET"
if clone_repo "K-Dense-AI/claude-scientific-skills" "${TMPDIR}/kdense-skills"; then
  for subdir in "scientific-skills" "skills" ".claude/skills" "docs"; do
    if [ -d "${TMPDIR}/kdense-skills/${subdir}" ]; then
      copy_skill_dirs "${TMPDIR}/kdense-skills/${subdir}" "$TARGET"
    fi
  done
  # Check for any remaining SKILL.md files in nested dirs
  find "${TMPDIR}/kdense-skills" -name "SKILL.md" -not -path "*/.git/*" 2>/dev/null | while read -r skill_file; do
    skill_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$skill_dir")"
    [ "$skill_name" = "kdense-skills" ] && continue
    if [ ! -d "${TARGET}/${skill_name}" ]; then
      mkdir -p "${TARGET}/${skill_name}"
      cp -r "${skill_dir}"/* "${TARGET}/${skill_name}/" 2>/dev/null || true
    fi
  done
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 7. ComposioHQ/awesome-claude-skills — top-level dirs
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[7/23] ComposioHQ/awesome-claude-skills${NC}"
TARGET="${SKILLS_DIR}/composio"
mkdir -p "$TARGET"
if clone_repo "ComposioHQ/awesome-claude-skills" "${TMPDIR}/composio-skills"; then
  if [ -d "${TMPDIR}/composio-skills/skills" ]; then
    copy_skill_dirs "${TMPDIR}/composio-skills/skills" "$TARGET"
  fi
  # Check top-level directories for skill content
  for d in "${TMPDIR}/composio-skills"/*/; do
    [ -d "$d" ] || continue
    dname="$(basename "$d")"
    [[ "$dname" == .* || "$dname" == "node_modules" || "$dname" == "scripts" || "$dname" == "skills" ]] && continue
    # Only copy dirs that contain SKILL.md or other .md skill files
    if [ -f "${d}SKILL.md" ] || ls "${d}"*.md >/dev/null 2>&1; then
      if [ ! -d "${TARGET}/${dname}" ]; then
        cp -r "${TMPDIR}/composio-skills/${dname}" "${TARGET}/"
      fi
    fi
  done
  n=$(find "$TARGET" -name "SKILL.md" -o -name "*.md" 2>/dev/null | grep -cv README || true)
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 8. sanjay3290/ai-skills — skills/ directory
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[8/23] sanjay3290/ai-skills${NC}"
TARGET="${SKILLS_DIR}/sanjay3290"
mkdir -p "$TARGET"
if clone_repo "sanjay3290/ai-skills" "${TMPDIR}/sanjay-skills"; then
  for subdir in "skills" ".claude/skills"; do
    if [ -d "${TMPDIR}/sanjay-skills/${subdir}" ]; then
      copy_skill_dirs "${TMPDIR}/sanjay-skills/${subdir}" "$TARGET"
    fi
  done
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 9. hashicorp/agent-skills — deeply nested **/skills/*/
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[9/23] hashicorp/agent-skills${NC}"
TARGET="${SKILLS_DIR}/hashicorp"
mkdir -p "$TARGET"
if clone_repo "hashicorp/agent-skills" "${TMPDIR}/hashicorp-skills"; then
  # Flatten all skill directories regardless of nesting depth
  find "${TMPDIR}/hashicorp-skills" -name "SKILL.md" -not -path "*/.git/*" 2>/dev/null | while read -r skill_file; do
    skill_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$skill_dir")"
    [ "$skill_name" = "hashicorp-skills" ] && continue
    mkdir -p "${TARGET}/${skill_name}"
    cp -r "${skill_dir}"/* "${TARGET}/${skill_name}/" 2>/dev/null || true
  done
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 10. michalparkola/tapestry-skills-for-claude-code
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[10/23] michalparkola/tapestry-skills-for-claude-code${NC}"
TARGET="${SKILLS_DIR}/tapestry"
mkdir -p "$TARGET"
if clone_repo "michalparkola/tapestry-skills-for-claude-code" "${TMPDIR}/tapestry-skills"; then
  for subdir in "skills" ".claude/skills"; do
    if [ -d "${TMPDIR}/tapestry-skills/${subdir}" ]; then
      copy_skill_dirs "${TMPDIR}/tapestry-skills/${subdir}" "$TARGET"
    fi
  done
  # Check top-level directories
  if [ "$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l)" -eq 0 ]; then
    for d in "${TMPDIR}/tapestry-skills"/*/; do
      [ -d "$d" ] || continue
      dname="$(basename "$d")"
      [[ "$dname" == .* || "$dname" == "node_modules" ]] && continue
      if [ -f "${d}SKILL.md" ]; then
        cp -r "${TMPDIR}/tapestry-skills/${dname}" "${TARGET}/"
      fi
    done
  fi
  n=$(find "$TARGET" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_SKILLS=$((TOTAL_SKILLS + n))
  echo -e "  ${GREEN}[done]${NC} ${n} skills"
fi

# ─────────────────────────────────────────────────────────────
# 11-21. Individual skill repos (single skill per repo)
# ─────────────────────────────────────────────────────────────

extract_single_skill() {
  local idx="$1"
  local repo="$2"
  local target_name="$3"

  echo -e "${BOLD}[${idx}/23] ${repo}${NC}"
  local target="${SKILLS_DIR}/${target_name}"
  mkdir -p "$target"
  local clone_dir="${TMPDIR}/$(echo "$repo" | tr '/' '-')"

  if clone_repo "$repo" "$clone_dir"; then
    local found=false

    # Check for SKILL.md in standard locations
    local skill_files
    skill_files=$(find "$clone_dir" -name "SKILL.md" -not -path "*/.git/*" 2>/dev/null)

    if [ -n "$skill_files" ]; then
      while IFS= read -r skill_file; do
        local skill_dir skill_name
        skill_dir="$(dirname "$skill_file")"
        skill_name="$(basename "$skill_dir")"
        if [ "$skill_name" = "$(basename "$clone_dir")" ]; then
          # SKILL.md is at repo root — copy into target directly
          cp "$skill_file" "${target}/SKILL.md"
          for support in scripts references examples; do
            [ -d "${clone_dir}/${support}" ] && cp -r "${clone_dir}/${support}" "${target}/"
          done
        else
          mkdir -p "${target}/${skill_name}"
          cp -r "${skill_dir}"/* "${target}/${skill_name}/" 2>/dev/null || true
        fi
      done <<< "$skill_files"
      found=true
    fi

    # If no SKILL.md found, look for any skill-like .md file
    if [ "$found" = false ]; then
      for md in "$clone_dir"/*.md; do
        [ -f "$md" ] || continue
        mdname="$(basename "$md")"
        [[ "$mdname" == "README.md" || "$mdname" == "LICENSE.md" || "$mdname" == "CHANGELOG.md" || "$mdname" == "CONTRIBUTING.md" ]] && continue
        cp "$md" "${target}/SKILL.md"
        found=true
        break
      done
    fi

    # Last resort: use README as skill doc
    if [ "$found" = false ] && [ -f "${clone_dir}/README.md" ]; then
      cp "${clone_dir}/README.md" "${target}/SKILL.md"
    fi

    local n
    n=$(find "$target" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_SKILLS=$((TOTAL_SKILLS + n))
    echo -e "  ${GREEN}[done]${NC} ${n} skills"
  fi
}

extract_single_skill "11" "jthack/ffuf_claude_skill" "ffuf-claude-skill"
extract_single_skill "12" "omkamal/pypict-claude-skill" "pypict-claude-skill"
extract_single_skill "13" "alonw0/web-asset-generator" "web-asset-generator"
extract_single_skill "14" "agamm/claude-code-owasp" "owasp-security"
extract_single_skill "15" "coffeefuelbump/csv-data-summarizer-claude-skill" "csv-data-summarizer"
extract_single_skill "16" "smerchek/claude-epub-skill" "claude-epub-skill"
extract_single_skill "17" "ryanbbrown/revealjs-skill" "revealjs-skill"
extract_single_skill "18" "wrsmith108/linear-claude-skill" "linear-claude-skill"
extract_single_skill "19" "wrsmith108/varlock-claude-skill" "varlock-claude-skill"
extract_single_skill "20" "huifer/Claude-Ally-Health" "claude-ally-health"
extract_single_skill "21" "Square-Zero-Labs/video-prompting-skill" "video-prompting-skill"

# ─────────────────────────────────────────────────────────────
# 22. Hooks: johnlindquist/claude-hooks
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[22/23] johnlindquist/claude-hooks (hook)${NC}"
TARGET="${HOOKS_DIR}/johnlindquist-claude-hooks"
mkdir -p "$TARGET"
if clone_repo "johnlindquist/claude-hooks" "${TMPDIR}/claude-hooks"; then
  rsync -a --exclude='.git' "${TMPDIR}/claude-hooks/" "$TARGET/" 2>/dev/null || \
    cp -r "${TMPDIR}/claude-hooks"/* "$TARGET/" 2>/dev/null || true
  echo -e "  ${GREEN}[done]${NC} hook framework"
fi

# ─────────────────────────────────────────────────────────────
# 23. Hooks: codeinbox/claude-code-discord
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}[23/23] codeinbox/claude-code-discord (hook)${NC}"
TARGET="${HOOKS_DIR}/claude-code-discord"
mkdir -p "$TARGET"
if clone_repo "codeinbox/claude-code-discord" "${TMPDIR}/claude-code-discord"; then
  rsync -a --exclude='.git' "${TMPDIR}/claude-code-discord/" "$TARGET/" 2>/dev/null || \
    cp -r "${TMPDIR}/claude-code-discord"/* "$TARGET/" 2>/dev/null || true
  echo -e "  ${GREEN}[done]${NC} Discord/Slack hook"
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Download complete!${NC}"
echo ""

echo -e "${CYAN}Skills by source:${NC}"
for source_dir in "${SKILLS_DIR}"/*/; do
  [ -d "$source_dir" ] || continue
  source_name="$(basename "$source_dir")"
  n=$(find "$source_dir" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] && echo -e "  ${source_name}: ${GREEN}${n}${NC}"
done

echo ""
FINAL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}${BOLD}Total: ${FINAL_COUNT} community skills${NC}"
echo -e "${CYAN}Location:${NC} ${SKILLS_DIR}"
