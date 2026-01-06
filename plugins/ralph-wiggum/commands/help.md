---
description: Show Ralph Wiggum plugin help and documentation
---

# Ralph Wiggum Plugin - Windows Edition

A self-referential development loop that iteratively improves on tasks until completion.

## How It Works

Ralph creates a feedback loop where:
1. You give Claude a task with a completion condition
2. The stop hook intercepts exit attempts
3. The same prompt is fed back with your previous work visible
4. Claude iteratively improves until the task is truly complete

## Commands

### `/ralph-wiggum:ralph-loop [prompt] [options]`

Start a new loop with the given task.

**Options:**
- `--max-iterations <n>` - Stop after N iterations (default: unlimited)
- `--completion-promise '<text>'` - Text that signals completion

**Examples:**
```
/ralph-wiggum:ralph-loop Build a REST API --completion-promise "ALL TESTS PASS" --max-iterations 30
/ralph-wiggum:ralph-loop Fix the authentication bug --max-iterations 10
/ralph-wiggum:ralph-loop Refactor the cache layer
```

### `/ralph-wiggum:cancel-ralph`

Force-stop an active loop and cleanup state files.

## Completion

To signal completion, output:
```
<promise>YOUR_COMPLETION_TEXT</promise>
```

**IMPORTANT**: Only output this when the statement is genuinely TRUE.

## Monitoring

Check current iteration:
```powershell
Get-Content .claude/ralph-loop.local.md | Select-String "iteration:"
```

View full state:
```powershell
Get-Content .claude/ralph-loop.local.md
```

## Best Practices

1. **Clear Completion Criteria**: Define what "done" means precisely
2. **Reasonable Limits**: Set max-iterations as a safety net
3. **Verifiable Promises**: Use promises that can be objectively verified (tests pass, linter clean, etc.)
4. **Incremental Tasks**: Break large tasks into smaller loops

## Technical Details

- State file: `.claude/ralph-loop.local.md`
- Hook type: Stop (intercepts session exit)
- Scripts: PowerShell (Windows native)
