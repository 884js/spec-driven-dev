#!/bin/bash
for f in "$CLAUDE_PROJECT_DIR"/docs/plans/*/state.json; do
  if [ -f "$f" ]; then
    # 完了済み feature はスキップ
    if grep -q '"phase".*"done"' "$f"; then
      continue
    fi
    FNAME=$(basename "$(dirname "$f")")
    echo ""
    echo "## Feature State ($FNAME)"
    cat "$f"
  fi
done
exit 0
