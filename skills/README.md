# Skills

仕様駆動開発のワークフローを構成するスキル群。

## ワークフロー

```
plan → implement → verify
          ↑          |
          └── revise ←┘
```

## スキル一覧

| スキル | 概要 | 前提 |
|--------|------|------|
| **plan** | 要件定義・技術設計・実装計画を1コマンドで生成。対話で要件確認 → 技術設計を一括提示 → plan.md 生成 | なし |
| **implement** | 実装。ブランチ作成、タスク単位のコーディング、テスト、PR作成。中断・再開対応 | plan 完了 |
| **verify** | 検証。実装コードからデータフロー抽出 → plan.md との双方向乖離検出 | implement 完了 |
| **revise** | 仕様修正。plan.md の特定セクション編集 + 整合性チェック | 任意のタイミング |

## 出力先

全スキルの成果物は `docs/{feature-name}/` に格納される。

```
docs/{feature-name}/
├── plan.md                      ← plan
├── project-context.md           ← plan
└── implementation-summary.md    ← verify
```
