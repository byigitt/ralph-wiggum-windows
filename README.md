# Ralph Wiggum - Windows Edition

> A Windows-compatible port of the official Ralph Wiggum plugin for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)](https://www.microsoft.com/windows)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet.svg)](https://claude.ai)

## Why This Exists

The [official Ralph Wiggum plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-wiggum) from Anthropic uses **Bash scripts** which don't work natively on Windows. This port replaces all Bash scripts with **PowerShell equivalents**, making the plugin fully functional on Windows systems.

## What is Ralph Wiggum?

Ralph Wiggum is a self-referential development loop plugin for Claude Code. It creates an iterative feedback loop where:

1. You give Claude a task with a completion condition
2. Claude works on the task and attempts to exit
3. The stop hook intercepts the exit and feeds the same prompt back
4. Claude sees its previous work in files and continues iterating
5. The loop continues until the task is truly complete (or max iterations reached)

This is incredibly powerful for complex development tasks where multiple iterations of refinement are needed.

## Installation

### Option 1: Install via Claude Code CLI (Recommended)

```bash
claude plugins:add byigitt/ralph-wiggum-windows
```

### Option 2: Manual Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/byigitt/ralph-wiggum-windows.git
   ```

2. Copy the plugin to your Claude plugins directory:
   ```powershell
   # Create plugins directory if it doesn't exist
   New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\plugins" -Force

   # Copy the plugin
   Copy-Item -Path "ralph-wiggum-windows\plugins\ralph-wiggum" -Destination "$env:USERPROFILE\.claude\plugins\ralph-wiggum" -Recurse
   ```

3. Restart Claude Code - the plugin will be automatically detected.

### Verify Installation

Run this command in Claude Code to verify the plugin is installed:
```
/ralph-wiggum:help
```

## Usage

### Starting a Loop

```
/ralph-wiggum:ralph-loop [your task] [options]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--max-iterations <n>` | Maximum iterations before auto-stop (default: unlimited) |
| `--completion-promise '<text>'` | Text that signals task completion |
| `-h, --help` | Show help message |

### Examples

**Build a feature with test verification:**
```
/ralph-wiggum:ralph-loop Build a REST API for user management --completion-promise "ALL TESTS PASS" --max-iterations 30
```

**Fix a bug with iteration limit:**
```
/ralph-wiggum:ralph-loop Fix the authentication timeout bug --max-iterations 10
```

**Open-ended refactoring:**
```
/ralph-wiggum:ralph-loop Refactor the database layer to use repository pattern
```

### Cancelling a Loop

Force-stop an active loop:
```
/ralph-wiggum:cancel-ralph
```

### Monitoring Progress

Check current iteration:
```powershell
Get-Content .claude/ralph-loop.local.md | Select-String "iteration:"
```

View full state:
```powershell
Get-Content .claude/ralph-loop.local.md
```

## How Completion Works

To signal that a task is complete, Claude must output:
```
<promise>YOUR_COMPLETION_TEXT</promise>
```

**Important:** The completion promise must be **genuinely true**. Claude is instructed not to lie just to escape the loop - the statement must be verifiable.

**Good completion promises:**
- `"ALL TESTS PASS"` - Verifiable by running tests
- `"LINTER CLEAN"` - Verifiable by running linter
- `"BUILD SUCCEEDS"` - Verifiable by running build
- `"FEATURE COMPLETE"` - Subjective but clear

## Commands Reference

| Command | Description |
|---------|-------------|
| `/ralph-wiggum:ralph-loop` | Start a new self-referential loop |
| `/ralph-wiggum:cancel-ralph` | Cancel an active loop |
| `/ralph-wiggum:help` | Show plugin documentation |

## Best Practices

1. **Set Clear Completion Criteria** - Define what "done" means precisely with `--completion-promise`
2. **Use Safety Limits** - Always set `--max-iterations` as a safety net for complex tasks
3. **Make Promises Verifiable** - Use completion promises that can be objectively verified (tests pass, build succeeds, etc.)
4. **Break Down Large Tasks** - For very large tasks, break them into smaller loops
5. **Monitor Progress** - Check the iteration count periodically to ensure the loop is making progress

## Requirements

- **Windows 10/11**
- **PowerShell 5.1+** (included with Windows)
- **Claude Code CLI**

## Project Structure

```
ralph-wiggum-windows/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace manifest
├── plugins/
│   └── ralph-wiggum/
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin manifest
│       ├── commands/
│       │   ├── ralph-loop.md  # /ralph-loop command
│       │   ├── cancel-ralph.md # /cancel-ralph command
│       │   └── help.md        # /help command
│       ├── hooks/
│       │   └── hooks.json     # Stop hook configuration
│       ├── scripts/
│       │   ├── setup-ralph-loop.ps1  # Loop initialization
│       │   └── stop-hook.ps1         # Main loop logic
│       └── README.md
└── README.md
```

## Technical Details

### How the Loop Works

1. **Setup Phase** (`setup-ralph-loop.ps1`):
   - Creates a state file at `.claude/ralph-loop.local.md`
   - Stores the prompt, iteration count, max iterations, and completion promise
   - Activates the stop hook

2. **Loop Phase** (`stop-hook.ps1`):
   - Intercepts Claude's exit attempts via the Stop hook
   - Reads the last assistant message from the transcript
   - Checks for completion promise or max iterations
   - If not complete, increments iteration and feeds the same prompt back
   - Claude sees its previous file changes and continues iterating

3. **Completion Phase**:
   - When completion promise is detected or max iterations reached
   - State file is deleted
   - Normal exit is allowed

### State File Format

```yaml
---
active: true
iteration: 5
max_iterations: 20
completion_promise: "ALL TESTS PASS"
started_at: "2024-01-15T10:30:00Z"
---

Build a REST API for user management
```

## Troubleshooting

**Plugin not detected:**
- Ensure the plugin is in `%USERPROFILE%\.claude\plugins\ralph-wiggum\`
- Restart Claude Code

**PowerShell execution policy error:**
- The scripts use `-ExecutionPolicy Bypass` to avoid issues
- If still blocked, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Loop not stopping:**
- Use `/ralph-wiggum:cancel-ralph` to force stop
- Manually delete `.claude/ralph-loop.local.md` if needed

## Credits

This is a Windows port of the official [Ralph Wiggum plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-wiggum) by Anthropic.

The original concept and design belong to the Anthropic team. This port simply replaces Bash scripts with PowerShell equivalents to enable Windows compatibility.

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**Made with frustration on Windows** - because Bash scripts don't work here.
