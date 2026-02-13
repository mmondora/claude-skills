#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# generate-readme.sh
# Auto-updates the skills catalog in README.md by reading
# frontmatter from .claude/skills/*/SKILL.md files.
#
# Usage:
#   ./scripts/generate-readme.sh
#
# Called automatically by .githooks/pre-commit
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"
README="${REPO_ROOT}/README.md"

# ── Cluster slug → sort order + display name (bash 3.2 compatible) ──
cluster_display() {
  case "$1" in
    foundations)              echo "01	Foundations" ;;
    cloud-infrastructure)    echo "02	Cloud & Infrastructure" ;;
    security-compliance)     echo "03	Security & Compliance" ;;
    testing-quality)         echo "04	Testing & Quality" ;;
    delivery-release)        echo "05	Delivery & Release" ;;
    documentation-diagrams)  echo "06	Documentation & Diagrams" ;;
    data-architecture)       echo "07	Data Architecture" ;;
    api-integration)         echo "08	API & Integration" ;;
    *)                       echo "99	Uncategorized" ;;
  esac
}

# ── Verify README exists with markers ──
if [[ ! -f "$README" ]]; then
  echo "Error: README.md not found at $README"
  exit 1
fi

if ! grep -q '<!-- SKILLS_START -->' "$README"; then
  echo "Error: missing <!-- SKILLS_START --> marker in README.md"
  exit 1
fi

# ── Collect skill data ──
tmpdata=$(mktemp)
skill_count=0

for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_file="${skill_dir}SKILL.md"
  [[ -f "$skill_file" ]] || continue

  skill_name=$(basename "$skill_dir")

  # Extract description from YAML frontmatter (single-line)
  description=$(grep '^description:' "$skill_file" | head -1 \
    | sed 's/^description: *"//;s/" *$//' \
    | sed 's/\. Use [a-z].*//' || true)

  # Extract cluster from YAML frontmatter
  cluster=$(grep '^cluster:' "$skill_file" | head -1 | sed 's/^cluster: *//' || true)
  cluster="${cluster:-uncategorized}"

  category_line=$(cluster_display "$cluster")
  sort_order=$(echo "$category_line" | cut -f1)
  category_name=$(echo "$category_line" | cut -f2)

  printf '%s\t%s\t%s\t%s\n' "$sort_order" "$category_name" "$skill_name" "$description" >> "$tmpdata"
  skill_count=$((skill_count + 1))
done

# ── Sort by category order, then skill name ──
sort -t$'\t' -k1,1 -k3,3 "$tmpdata" > "${tmpdata}.sorted"

# ── Generate catalog markdown ──
catalog_file=$(mktemp)
current_category=""

while IFS=$'\t' read -r _order category skill description; do
  if [[ "$category" != "$current_category" ]]; then
    [[ -n "$current_category" ]] && echo "" >> "$catalog_file"
    echo "### ${category}" >> "$catalog_file"
    echo "| Skill | What it covers |" >> "$catalog_file"
    echo "|-------|----------------|" >> "$catalog_file"
    current_category="$category"
  fi
  echo "| \`${skill}\` | ${description} |" >> "$catalog_file"
done < "${tmpdata}.sorted"

rm -f "$tmpdata" "${tmpdata}.sorted"

# ── Update README.md ──
tmpreadme=$(mktemp)

awk -v count="$skill_count" -v catfile="$catalog_file" '
  /^## Skills Catalog/ {
    print "## Skills Catalog (" count " skills)"
    next
  }
  /<!-- SKILLS_START -->/ {
    print
    print ""
    while ((getline line < catfile) > 0) print line
    close(catfile)
    skip = 1
    next
  }
  /<!-- SKILLS_END -->/ {
    print ""
    print
    skip = 0
    next
  }
  !skip { print }
' "$README" > "$tmpreadme"

mv "$tmpreadme" "$README"
rm -f "$catalog_file"

echo "README.md updated (${skill_count} skills)"
