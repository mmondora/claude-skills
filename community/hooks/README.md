# Community Hooks for Claude Code

Hooks are shell commands that execute in response to Claude Code lifecycle
events (tool calls, notifications, etc.). They extend Claude Code's
behavior without modifying skills.

## Available Hooks

### johnlindquist/claude-hooks (MIT)

A TypeScript framework for building Claude Code hooks with type safety
and structured patterns.

**Source**: [github.com/johnlindquist/claude-hooks](https://github.com/johnlindquist/claude-hooks)

**Install**:
```bash
# Copy the hook framework into your project
cp -r community/hooks/johnlindquist-claude-hooks /path/to/project/.claude/hooks/
```

**What it provides**:
- TypeScript-based hook definitions
- Pre/post tool call handlers
- Notification hooks
- Structured logging for hook events

---

## Other Community Hooks (Reference Only)

The following hooks were mentioned in community discussions but are
referenced here for documentation only (not bundled in this repo):

### CCHooks by GowayLee
Python-based hook framework. See the original project for installation.

### beyondcode/claude-code-hooks
Laravel/PHP-oriented hook framework.

### Claudio by Christopher Toth
OS-native sounds triggered by Claude Code events (macOS, Windows, Linux).

### CC Notify
Desktop notifications for Claude Code task completion.

### codeinbox/claude-code-discord
Discord and Slack notifications for Claude Code events. Sends messages
when tasks complete or errors occur.

**Source**: [github.com/codeinbox/claude-code-discord](https://github.com/codeinbox/claude-code-discord)

### fcakyon Code Quality Collection
Pre-commit hooks for code quality: linting, formatting, type checking.

### TypeScript Quality Hooks by bartolli
TypeScript-specific quality hooks: strict mode enforcement, type coverage.

---

## How Hooks Work

Claude Code hooks are configured in `.claude/settings.json` or
`.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File being modified'"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/post-tool-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook Events

| Event | When it fires |
|-------|--------------|
| `PreToolUse` | Before a tool is executed |
| `PostToolUse` | After a tool completes |
| `Notification` | When Claude sends a notification |
| `Stop` | When Claude stops generating |

See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for the full hooks API.
