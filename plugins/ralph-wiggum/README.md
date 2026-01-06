# Ralph Wiggum Plugin - Windows Edition

Self-referential development loop for Claude Code on Windows.

## Installation

Plugin is installed at: `~/.claude/plugins/ralph-wiggum/`

No additional setup required - Claude Code will automatically detect it.

## Usage

```
/ralph-wiggum:ralph-loop Build a todo API --completion-promise "DONE" --max-iterations 20
```

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-wiggum:ralph-loop` | Start a new loop |
| `/ralph-wiggum:cancel-ralph` | Cancel active loop |
| `/ralph-wiggum:help` | Show documentation |

## How It Works

1. You start a loop with a task and completion criteria
2. The Stop hook intercepts Claude's exit attempts
3. Same prompt is fed back - you see your previous work in files
4. Loop continues until completion promise is output or max iterations reached

## Requirements

- Windows 10/11
- PowerShell 5.1+ (included with Windows)
- Claude Code CLI

## Files

```
ralph-wiggum/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   ├── ralph-loop.md        # /ralph-loop command
│   ├── cancel-ralph.md      # /cancel-ralph command
│   └── help.md              # /help command
├── hooks/
│   └── hooks.json           # Stop hook configuration
├── scripts/
│   ├── stop-hook.ps1        # Main loop logic
│   └── setup-ralph-loop.ps1 # Loop initialization
└── README.md
```

## Credits

Windows port of the official [Ralph Wiggum plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-wiggum) by Anthropic.
