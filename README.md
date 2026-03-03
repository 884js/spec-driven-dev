# spec-flow

仕様駆動で開発を進める Claude Code プラグイン。
要件ヒアリングから設計・実装・検証までを 4 つのスキルでガイドします。

## モチベーション

AI に計画なしで実装を任せると迷走する。Claude Code のプラン機能で軽減できるが、フォーマットが都度ブレてラリーが増えるのを避けたい。

spec-flow は仕様駆動のワークフローを「フォーマットごと」プラグイン化し、スキルを呼ぶだけで構造化された成果物が出るようにする意図で作った。

## インストール

```
/install-plugin 884js/spec-flow
```

## ワークフロー

```
spec → build → check → done
  ^                |
  |   (NEEDS_FIX)  |
  +----------------+

debug は任意タイミングで独立起動
```

| ステップ | スキル | 役割 |
|---------|--------|------|
| 1 | `/spec-flow:spec` | 要件ヒアリング → 統合分析 → 方向性確認 → plan.md 生成。大規模機能では PR 分割付き progress.md も同時生成 |
| 2 | `/spec-flow:build` | plan.md に沿ってブランチ作成〜タスク順の実装〜ビルド確認〜PR 作成まで実行 |
| 3 | `/spec-flow:check` | 実装コードと plan.md を突合し PASS / PARTIAL / NEEDS_FIX の3段階で検証 |
| - | `/spec-flow:debug` | 実行時の不具合を推測禁止で根本原因調査。feature モード / standalone モード対応 |

## スキル詳細

### spec

要件ヒアリングから技術設計・実装計画までを 1 コマンドで完了します。
新規モード（plan.md 生成）と更新モード（check 結果や追加要求による plan.md 更新）の2モードを持ちます。
大規模機能では PR 分割・デリバリー順序の計画も統合して行います。

```
/spec-flow:spec ユーザー通知機能を追加したい
```

**出力**: `docs/plans/{feature-name}/plan.md`（+ 大規模時は `progress.md`）

### build

plan.md に沿って実装を進めます。ブランチ作成 → タスク順の実装 → ビルド確認 → PR 作成までを一貫してガイド。
progress.md によるタスク状態管理で中断・再開をサポートします。
実装中に仕様漏れを検出した場合は spec への差し戻しを促します。

```
/spec-flow:build
```

### check

実装コードを直接読み取り、plan.md との乖離を双方向で検出します。
結果を PASS（全条件充足）/ PARTIAL（軽微な不一致）/ NEEDS_FIX（重大な不一致）の3段階で判定し、result.md を生成します。
NEEDS_FIX の場合は spec での更新を提案し、ループを閉じます。

```
/spec-flow:check
```

### debug

推測での修正を禁止し、実際の実行フローをトレースして原因を特定してから修正方針を立てます。
plan.md がある場合は仕様と照合しながら調査する feature モード、plan.md なしで単発調査する standalone モードの2モードで動作します。

```
/spec-flow:debug エラーの症状を記述
```

## ライセンス

MIT
