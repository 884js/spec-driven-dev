# spec-flow

仕様駆動で開発を進める Claude Code プラグイン。
要件ヒアリングから設計・実装・検証までを 5 つのスキルでガイドします。

## モチベーション

AI に計画なしで実装を任せると迷走する。Claude Code のプラン機能で軽減できるが、フォーマットが都度ブレてラリーが増えるのを避けたい。

spec-flow は仕様駆動のワークフローを「フォーマットごと」プラグイン化し、スキルを呼ぶだけで構造化された成果物が出るようにする意図で作った。

## インストール

```
/install github:884js/spec-flow
```

## ワークフロー

```
plan → (strategy) → implement → verify
                        ↓
                    troubleshoot (不具合発生時)
```

| ステップ | スキル | 役割 |
|---------|--------|------|
| 1 | `/spec-flow:plan` | 要件ヒアリング → 技術設計 → 実装計画をプランファイルに出力 |
| 2 | `/spec-flow:strategy` | (任意) タスクの PR 分割・デリバリー順序を決定 |
| 3 | `/spec-flow:implement` | plan.md に沿ってブランチ作成〜実装〜PR 作成まで実行 |
| 4 | `/spec-flow:verify` | 実装コードとプランを突合し仕様通りか検証 |
| - | `/spec-flow:troubleshoot` | 実行時の不具合を推測禁止で根本原因調査 |

## スキル詳細

### plan

要件ヒアリングから技術設計・実装計画までを 1 コマンドで完了します。
対話で要件を確認しつつ、技術設計はモデルが一気に生成 → ユーザーレビューの「ハイブリッド」方式。

```
/spec-flow:plan ユーザー通知機能を追加したい
```

**出力**: `docs/plans/{feature-name}/plan.md`

### strategy

plan.md の実装タスク表を分析し、PR 分割・デリバリー順序・リスク判断をユーザーとの対話で決定します。
plan（何を作るか）と implement（作る）の間にある「どう分けて届けるか」を担うフェーズ。

```
/spec-flow:strategy
```

**出力**: `docs/plans/{feature-name}/progress.md`

### implement

plan.md に沿って実装を進めます。ブランチ作成 → タスク順の実装 → ビルド確認 → PR 作成までを一貫してガイド。
progress.md によるタスク状態管理で中断・再開をサポートします。

```
/spec-flow:implement
```

### verify

実装コードを直接読み取り、plan.md との乖離を双方向で検出します。
verifier エージェントが実コードと仕様書を突合し、検証レポートと result.md を生成します。

```
/spec-flow:verify
```

### troubleshoot

推測での修正を禁止し、実際の実行フローをトレースして原因を特定してから修正方針を立てます。
plan.md がなくても単発デバッグとして使えます。

```
/spec-flow:troubleshoot エラーの症状を記述
```

## ライセンス

MIT
