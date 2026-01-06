---
description: Start Ralph Wiggum loop in current session
allowed_tools: [Bash]
---

Start a self-referential development loop that iteratively improves on a task.

Execute the setup script to initialize the loop:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-loop.ps1" $ARGUMENTS
```

**Arguments:** $ARGUMENTS

The stop hook will now intercept all exit attempts and feed the same prompt back,
allowing you to see your previous work in files and iterate on improvements.

**CRITICAL**: You can ONLY declare the task complete when your completion promise
statement is entirely and unambiguously accurate. Do NOT output a false completion
promise just to escape the loop - this would be lying.

Your context persists through:
- Modified files in the working directory
- Git history showing your changes
- The iteration counter in .claude/ralph-loop.local.md
