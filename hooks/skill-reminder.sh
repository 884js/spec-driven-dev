#!/bin/bash
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/active-skill.md"
if [ -f "$STATE_FILE" ]; then
  cat "$STATE_FILE"
fi
exit 0
