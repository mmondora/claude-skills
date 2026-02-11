# Community Skills, Hooks & Tools

**1,300+ community-contributed skills** from 20+ open-source repositories, organized by source. These complement the 26 curated skills in `.claude/skills/`.

## How Community Skills Differ from Curated Skills

| | Curated (26) | Community (1,300+) |
|---|---|---|
| **Location** | `.claude/skills/` | `community/skills/` |
| **Format** | Standardized SKILL.md with frontmatter | Original format (varies by author) |
| **Quality** | Reviewed, versioned, consistent | As-is from source repos |
| **Auto-loaded** | Yes (by Claude Code) | No (must be installed first) |

## Installing Community Skills

```bash
# Install a single community skill into your project
cp -r community/skills/obra-superpowers/brainstorming /path/to/project/.claude/skills/

# Install all skills from one source
cp -r community/skills/obra-superpowers/* /path/to/project/.claude/skills/

# Install everything from all community sources
for d in community/skills/*/; do
  cp -r "$d"* /path/to/project/.claude/skills/
done
```

Or use the installer with the `--include-community` flag:

```bash
./scripts/install-skills.sh /path/to/project --include-community
```

## Updating Community Skills

Re-run the download script to pull the latest versions from all source repos:

```bash
./community/download-community.sh --clean
```

---

## Skills Catalog

### obra/superpowers (14 skills) — MIT

Best-practice development workflows: TDD, debugging, code review, planning.

| Skill | Description |
|-------|-------------|
| `brainstorming` | Structured brainstorming methodology |
| `dispatching-parallel-agents` | Running multiple Claude agents in parallel |
| `executing-plans` | Step-by-step plan execution |
| `finishing-a-development-branch` | Branch completion checklist |
| `receiving-code-review` | Handling code review feedback |
| `requesting-code-review` | Preparing code for review |
| `subagent-driven-development` | Development with specialized sub-agents |
| `systematic-debugging` | Methodical debugging approach |
| `test-driven-development` | TDD workflow for Claude Code |
| `using-git-worktrees` | Git worktree workflows |
| `using-superpowers` | Meta-skill for using the superpowers collection |
| `verification-before-completion` | Pre-completion verification checklist |
| `writing-plans` | Writing implementation plans |
| `writing-skills` | How to write Claude Code skills |

Source: [github.com/obra/superpowers](https://github.com/obra/superpowers)

### obra/superpowers-lab (4 skills) — MIT

Experimental skills from the superpowers ecosystem.

| Skill | Description |
|-------|-------------|
| `finding-duplicate-functions` | Detecting duplicate code |
| `mcp-cli` | MCP CLI usage |
| `slack-messaging` | Slack integration |
| `using-tmux-for-interactive-commands` | Tmux for interactive workflows |

Source: [github.com/obra/superpowers-lab](https://github.com/obra/superpowers-lab)

### anthropics/skills (16 skills) — Anthropic

Official skills from Anthropic covering document generation, design, and dev tools.

| Skill | Description |
|-------|-------------|
| `algorithmic-art` | Generative algorithmic art |
| `brand-guidelines` | Brand guideline documents |
| `canvas-design` | Canvas-based design |
| `doc-coauthoring` | Document co-authoring |
| `docx` | DOCX document generation |
| `frontend-design` | Frontend design patterns |
| `internal-comms` | Internal communications |
| `mcp-builder` | Building MCP servers |
| `pdf` | PDF document generation |
| `pptx` | PowerPoint generation |
| `skill-creator` | Creating new Claude Code skills |
| `slack-gif-creator` | Slack GIF creation |
| `theme-factory` | Theme/design system creation |
| `web-artifacts-builder` | Web artifact generation |
| `webapp-testing` | Web application testing |
| `xlsx` | Excel spreadsheet generation |

Source: [github.com/anthropics/skills](https://github.com/anthropics/skills)

### trailofbits/skills (52 skills) — CC-BY-SA-4.0

Security analysis, fuzzing, code auditing, and vulnerability scanning.

| Skill | Description |
|-------|-------------|
| `address-sanitizer` | AddressSanitizer analysis |
| `aflpp` | AFL++ fuzzing |
| `algorand-vulnerability-scanner` | Algorand security scanning |
| `ask-questions-if-underspecified` | Requirement clarification |
| `atheris` | Python fuzzing with Atheris |
| `audit-context-building` | Security audit context |
| `audit-prep-assistant` | Audit preparation |
| `cairo-vulnerability-scanner` | Cairo contract scanning |
| `cargo-fuzz` | Rust fuzzing with cargo-fuzz |
| `claude-in-chrome-troubleshooting` | Chrome extension debugging |
| `code-maturity-assessor` | Code maturity assessment |
| `codeql` | CodeQL analysis |
| `constant-time-analysis` | Timing attack analysis |
| `constant-time-testing` | Timing attack testing |
| `cosmos-vulnerability-scanner` | Cosmos chain scanning |
| `coverage-analysis` | Code coverage analysis |
| `debug-buttercup` | Buttercup debugging |
| `devcontainer-setup` | Dev container configuration |
| `differential-review` | Differential code review |
| `dwarf-expert` | DWARF debugging format |
| `entry-point-analyzer` | Entry point analysis |
| `firebase-apk-scanner` | Firebase APK security |
| `fix-review` | Fix review process |
| `fuzzing-dictionary` | Fuzzing dictionary creation |
| `fuzzing-obstacles` | Overcoming fuzzing obstacles |
| `guidelines-advisor` | Security guidelines |
| `harness-writing` | Fuzzing harness writing |
| `insecure-defaults` | Finding insecure defaults |
| + 24 more | See `community/skills/trailofbits/` |

Source: [github.com/trailofbits/skills](https://github.com/trailofbits/skills)

### jeffallan/claude-skills (66 skills) — MIT

Full-stack development across 30+ frameworks and languages.

| Skill | Description |
|-------|-------------|
| `angular-architect` | Angular architecture |
| `api-designer` | API design |
| `cloud-architect` | Cloud architecture |
| `code-reviewer` | Code review |
| `cpp-pro` | C++ development |
| `csharp-developer` | C# development |
| `database-optimizer` | Database optimization |
| `devops-engineer` | DevOps practices |
| `django-expert` | Django development |
| `fastapi-expert` | FastAPI development |
| `flutter-expert` | Flutter development |
| `golang-pro` | Go development |
| `java-architect` | Java architecture |
| `javascript-pro` | JavaScript development |
| `kotlin-specialist` | Kotlin development |
| `kubernetes-specialist` | Kubernetes operations |
| `laravel-specialist` | Laravel development |
| `nextjs-architect` | Next.js architecture |
| `python-pro` | Python development |
| `react-expert` | React development |
| `rust-developer` | Rust development |
| `swift-architect` | Swift architecture |
| `typescript-pro` | TypeScript development |
| `vue-expert` | Vue.js development |
| + 42 more | See `community/skills/jeffallan/` |

Source: [github.com/jeffallan/claude-skills](https://github.com/jeffallan/claude-skills)

### K-Dense-AI/claude-scientific-skills (149 skills) — MIT

Scientific computing: bioinformatics, chemistry, ML, data science, and more.

| Skill | Description |
|-------|-------------|
| `alphafold-database` | AlphaFold protein structure |
| `anndata` | Annotated data matrices |
| `astropy` | Astronomy and astrophysics |
| `biopython` | Bioinformatics with BioPython |
| `cirq` | Quantum computing with Cirq |
| `cobrapy` | Metabolic modeling |
| `dask` | Parallel computing |
| `deepchem` | Deep learning for chemistry |
| `matplotlib` | Data visualization |
| `networkx` | Network analysis |
| `numpy` | Numerical computing |
| `pandas` | Data manipulation |
| `pytorch` | Deep learning |
| `rdkit` | Cheminformatics |
| `scanpy` | Single-cell analysis |
| `scikit-learn` | Machine learning |
| `scipy` | Scientific computing |
| `seaborn` | Statistical visualization |
| `tensorflow` | Machine learning |
| + 130 more | See `community/skills/k-dense-scientific/` |

Source: [github.com/K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills)

### ComposioHQ/awesome-claude-skills (939 skills) — No license

Service automations and integrations: Slack, Airtable, GitHub, Notion, and hundreds more.

This is the largest collection, covering integrations with 100+ services. Each skill provides Claude Code with the ability to interact with a specific service or API.

Browse: `community/skills/composio/`

Source: [github.com/ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)

### sanjay3290/ai-skills (14 skills) — Apache-2.0

Google Workspace integrations and research tools.

| Skill | Description |
|-------|-------------|
| `deep-research` | Deep research methodology |
| `gmail` | Gmail integration |
| `google-calendar` | Google Calendar |
| `google-chat` | Google Chat |
| `google-docs` | Google Docs |
| `google-drive` | Google Drive |
| `google-sheets` | Google Sheets |
| `google-slides` | Google Slides |
| `imagen` | Google Imagen |
| `jules` | Jules AI |
| `manus` | Manus AI |
| `notebooklm` | NotebookLM |
| `outline` | Outline wiki |
| `postgres` | PostgreSQL |

Source: [github.com/sanjay3290/ai-skills](https://github.com/sanjay3290/ai-skills)

### hashicorp/agent-skills (13 skills) — MPL-2.0

Terraform and HashiCorp ecosystem tooling.

| Skill | Description |
|-------|-------------|
| `aws-ami-builder` | AWS AMI building with Packer |
| `azure-image-builder` | Azure image building |
| `azure-verified-modules` | Azure verified modules |
| `new-terraform-provider` | Creating Terraform providers |
| `provider-actions` | Provider action patterns |
| `provider-resources` | Provider resource patterns |
| `push-to-registry` | Registry publishing |
| `refactor-module` | Module refactoring |
| `run-acceptance-tests` | Acceptance testing |
| `terraform-stacks` | Terraform Stacks |
| `terraform-style-guide` | Terraform style conventions |
| `terraform-test` | Terraform testing |
| `windows-builder` | Windows image building |

Source: [github.com/hashicorp/agent-skills](https://github.com/hashicorp/agent-skills)

### michalparkola/tapestry-skills (4 skills) — MIT

Content extraction and learning workflow skills.

| Skill | Description |
|-------|-------------|
| `article-extractor` | Web article extraction |
| `ship-learn-next` | Iterative learning workflow |
| `tapestry` | Tapestry knowledge management |
| `youtube-transcript` | YouTube transcript extraction |

Source: [github.com/michalparkola/tapestry-skills-for-claude-code](https://github.com/michalparkola/tapestry-skills-for-claude-code)

### Individual Skill Repos

| Skill | Source | License |
|-------|--------|---------|
| `ffuf-claude-skill` | [jthack/ffuf_claude_skill](https://github.com/jthack/ffuf_claude_skill) | No license |
| `pypict-claude-skill` | [omkamal/pypict-claude-skill](https://github.com/omkamal/pypict-claude-skill) | MIT |
| `web-asset-generator` | [alonw0/web-asset-generator](https://github.com/alonw0/web-asset-generator) | MIT |
| `owasp-security` | [agamm/claude-code-owasp](https://github.com/agamm/claude-code-owasp) | MIT |
| `csv-data-summarizer` | [coffeefuelbump/csv-data-summarizer-claude-skill](https://github.com/coffeefuelbump/csv-data-summarizer-claude-skill) | No license |
| `claude-epub-skill` | [smerchek/claude-epub-skill](https://github.com/smerchek/claude-epub-skill) | MIT |
| `revealjs-skill` | [ryanbbrown/revealjs-skill](https://github.com/ryanbbrown/revealjs-skill) | MIT |
| `linear-claude-skill` | [wrsmith108/linear-claude-skill](https://github.com/wrsmith108/linear-claude-skill) | MIT |
| `varlock-claude-skill` | [wrsmith108/varlock-claude-skill](https://github.com/wrsmith108/varlock-claude-skill) | MIT |
| `claude-ally-health` | [huifer/Claude-Ally-Health](https://github.com/huifer/Claude-Ally-Health) | MIT |
| `video-prompting-skill` | [Square-Zero-Labs/video-prompting-skill](https://github.com/Square-Zero-Labs/video-prompting-skill) | MIT |

---

## Hooks

Community hooks extend Claude Code with lifecycle event handlers. See [hooks/README.md](hooks/README.md) for details.

| Hook | Source | What it does |
|------|--------|-------------|
| johnlindquist/claude-hooks | [Repo](https://github.com/johnlindquist/claude-hooks) | TypeScript hook framework |

---

## Copyright & Licensing

Community skills are copyright their respective authors and distributed
under their original licenses. See [LICENSES.md](LICENSES.md) for the
complete license summary.

Skills from repos without an explicit license are redistributed from
public repositories. If you are an author and wish to specify a license
or request removal, please open an issue.

## Credits

Community skills were discovered via a
[Reddit review of 30+ community Claude skills](https://www.reddit.com/r/ClaudeAI/comments/1ok9v3d/).
Thanks to all the authors who shared their work with the community.
