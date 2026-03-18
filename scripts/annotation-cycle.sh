#!/usr/bin/env bash
# Annotation Cycle — サーバー起動・ブラウザ表示・イベント待機
#
# Usage:
#   annotation-cycle.sh --feature <feature-name> [--wait-only]
#
# --wait-only: サーバー起動・ブラウザ表示をスキップし、ポーリングのみ行う
#              （コメント修正後の再待機に使用）
#
# 出力（stdout）:
#   PORT:{port}           — サーバーのポート番号（--wait-only 時は出力しない）
#   COMMENTS_SAVED        — コメントが送信された
#   REVIEW_DONE           — レビューが完了した

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_SCRIPT="${SCRIPT_DIR}/annotation-viewer/server.py"
SIGNAL_DIR="/tmp/spec-flow-review"
LOCK_FILE="/tmp/annotation-viewer.lock"

# ─── Parse args ───

FEATURE=""
WAIT_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --feature)   FEATURE="$2"; shift 2 ;;
        --wait-only) WAIT_ONLY=true; shift ;;
        *)           echo "Error: Unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ -n "$FEATURE" ]] || { echo "Error: --feature is required" >&2; exit 1; }

FEATURE_DIR="${SIGNAL_DIR}/${FEATURE}"

# ─── Start server + open browser ───

if [[ "$WAIT_ONLY" == false ]]; then
    # Clean up stale signal files
    rm -f "${FEATURE_DIR}/comments.json" "${FEATURE_DIR}/review-done.flag" 2>/dev/null

    # Start server in background, capture stdout to temp file
    PORT_FILE="$(mktemp)"
    python3 "$SERVER_SCRIPT" --feature "$FEATURE" > "$PORT_FILE" 2>/dev/null &
    SERVER_PID=$!

    # Wait for PORT line (max 10 seconds)
    PORT=""
    for _ in $(seq 1 20); do
        if [[ -s "$PORT_FILE" ]]; then
            PORT="$(grep -m1 '^PORT:' "$PORT_FILE" 2>/dev/null | sed 's/PORT://')"
            [[ -n "$PORT" ]] && break
        fi
        sleep 0.5
    done
    rm -f "$PORT_FILE"

    # Fallback: check lock file (server may have registered to existing instance)
    if [[ -z "$PORT" ]] && [[ -f "$LOCK_FILE" ]]; then
        PORT="$(cat "$LOCK_FILE")"
    fi

    if [[ -z "$PORT" ]]; then
        echo "Error: Could not determine server port" >&2
        exit 1
    fi

    echo "PORT:${PORT}"

    # Open browser
    if command -v open &>/dev/null; then
        open "http://localhost:${PORT}"
    elif command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:${PORT}"
    fi
fi

# ─── Poll for events ───

while true; do
    if [[ -f "${FEATURE_DIR}/review-done.flag" ]]; then
        echo "REVIEW_DONE"
        exit 0
    fi

    if [[ -f "${FEATURE_DIR}/comments.json" ]]; then
        rm -f "${FEATURE_DIR}/comments.json"
        echo "COMMENTS_SAVED"
        exit 0
    fi

    sleep 3
done
