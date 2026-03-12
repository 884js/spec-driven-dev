# リサーチ: brownfield-hooks plan.md の技術的実現可能性

調査日: 2026-03-12
調査タイプ: 複合

## 調査ゴール

brownfield-hooks plan.md の全6タスクが技術的に実現可能かを検証する。

## 調査結果

### 総合評価: 全タスク実現可能（ただし1点修正が必要）

| タスク# | 対象 | 実現可能性 | リスク |
|---------|------|-----------|--------|
| 1 | analyzer 出力フォーマット拡張 | **可能** | 低 — セクション追加のみ |
| 2 | spec Step 3 拡張 | **可能** | 低 — 項目追加のみ |
| 3 | verifier 出力フォーマット拡張 | **可能** | 低 — 分類追加のみ |
| 4 | check 検証観点追加 | **可能** | 低 — プロンプト拡張のみ |
| 5 | phase-detector.sh 新規作成 | **可能（要修正）** | 中 — stdout の注入方式を変更する必要あり |
| 6 | hooks.json 更新 | **可能** | 低 — エントリ置換のみ |

### 発見事項

#### タスク #1-4（Brownfield 検証）: 問題なし

- analyzer の出力フォーマットはセクション追加・省略を想定した設計（出典: `agents/analyzer/references/formats/output.md`）
- verifier の不一致分類は箇条書きリストへの項目追加で対応可能（出典: `agents/verifier/references/formats/output.md`）
- spec SKILL.md は274行、check SKILL.md は167行で、ともに500行制限に十分な余裕あり

#### タスク #5-6（Hooks フェーズ遷移）: stdout 注入方式に修正が必要

**plan.md の設計**:
> PostToolUse で stdout にメッセージを出力 → Claude のコンテキストに注入

**実際の仕様**（公式ドキュメント: https://code.claude.com/docs/en/hooks）:

| イベント | stdout の扱い |
|---------|-------------|
| UserPromptSubmit | **プレーンテキストが自動でコンテキストに追加される** |
| PostToolUse | **stdout はデフォルトで Claude に見えない**（verbose モードのみ） |

PostToolUse で Claude にメッセージを伝えるには、**JSON 形式で `additionalContext` を返す**必要がある:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "全タスク完了。/check で検証できます。"
  }
}
```

または `decision: "block"` + `reason` でフィードバックを返す方式もある。

#### PostToolUse の stdin 構造（確認済み）

```json
{
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/absolute/path/to/file.txt",
    "content": "..."
  },
  "tool_response": { "filePath": "...", "success": true }
}
```

- `tool_input.file_path` で書き込み先パスを取得できる（`jq -r '.tool_input.file_path'`）
- matcher `"Write|Edit"` で書き込み系ツールのみに絞り込める

#### hooks タイムアウト

- command タイプのデフォルト: 600秒（plan.md の非機能要件「5秒以内」は十分達成可能）
- `timeout` フィールドで個別に設定可能

## 推奨・結論

**plan.md の修正が必要な箇所**:

1. **phase-detector.sh の stdout 出力方式**: プレーンテキスト stdout → JSON 形式（`additionalContext`）に変更
2. **データフロー図の修正**: `Hook-->>Claude: 「全タスク完了...」` の矢印を、JSON 出力経由に修正

それ以外の設計判断は全て妥当であり、そのまま実装可能。

## 次のステップ

- plan.md の phase-detector.sh 関連セクションを修正（stdout → additionalContext JSON）
- `/build brownfield-hooks` で実装開始
