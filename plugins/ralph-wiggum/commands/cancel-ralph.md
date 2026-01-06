---
description: Cancel active Ralph loop and cleanup state
allowed_tools: [Bash, Read]
---

Cancel the active Ralph Wiggum loop.

**Allowed operations:**

1. Check if loop is active:
```bash
test -f .claude/ralph-loop.local.md && echo "Active" || echo "No active loop"
```

2. If active, read current state to report iteration count, then delete:
```bash
cat .claude/ralph-loop.local.md
rm .claude/ralph-loop.local.md
```

3. If no active loop, inform the user.

Report the iteration number that was reached when cancelling.
