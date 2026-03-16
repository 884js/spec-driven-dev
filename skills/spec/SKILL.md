---
name: spec
description: "Generates or updates plan.md through requirements hearing, integrated analysis, and design dialogue. Handles both new spec creation and update mode (from check results). Use when starting a new feature or updating an existing spec."
allowed-tools: Read Glob Grep Edit Task Bash
metadata:
  triggers: spec, plan, create spec, new spec, design, requirements, update spec, 仕様書作成, 要件定義, 仕様更新
---

# 仕様作成（Spec）

ユーザーの要求から plan.md + progress.md を生成するスキル。

入力: ユーザーの要求（$ARGUMENTS または対話）
出力: `docs/plans/{feature-name}/plan.md` + `progress.md`

**パスルール**: `docs/plans/{feature-name}/` はカレントディレクトリ直下。`{feature-name}` は英語の kebab-case

## ワークフロー

```
Step 1: モード判定 + 要件ヒアリング
Step 2: 統合分析（analyzer）
Step 3: plan.md + progress.md 生成（writer）
Step 4: ブラウザレビュー（Annotation Cycle）
Step 5: 次のアクション提示
```

---

## Step 1: モード判定 + 要件ヒアリング

### モード判定

```
Glob docs/plans/**/plan.md
```

- **plan.md なし** → 新規モード → ヒアリングへ
- **plan.md あり** → 更新モード: plan.md と result.md（あれば）を読み、変更点をヒアリングして Step 3 へ（Step 2 はスキップ）

### ヒアリング（新規モード）

$ARGUMENTS を評価し、**何を作りたいか** が明確なら Step 2 へ。

不明確な場合（空、動詞のみで対象不明、複数解釈可能）は AskUserQuestion で1往復だけ確認する。

受入条件・スコープ外・非機能要件は聞かない。これらは analyzer の結果をもとに writer が推測して生成する。

---

## Step 2: 統合分析（analyzer）

```
Task(subagent_type: analyzer):
  「このプロジェクトの統合分析を行ってください。
  追加機能の概要: {Step 1 で把握した機能概要}」
```

analyzer がプロジェクトコンテキスト・コードパターン・Git履歴を調査し、統合レポートを返す。

---

## Step 3: plan.md + progress.md 生成

### 3-a. plan.md 生成

```
Task(subagent_type: writer):
  「docs/plans/{feature-name}/plan.md を生成してください。
  ドキュメント種別: plan
  プロジェクト規約: {analyzer の要約}
  設計内容:
    概要: {ユーザーの要求}
    受入条件: {要求と分析結果から推測}
    スコープ: {要求と分析結果から推測}
    データフロー・バックエンド・DB・フロントエンド: {分析結果から推測}
    実装タスク: {依存関係付きタスク一覧}
    テスト方針: {テスト一覧}
  注意:
  - frontmatter は title, feature-name, status(done), created, updated を含める
  - ソースコードは含めない
  - 自己検証でセクション間の整合性を確認すること
  - 仕様に明示されていないが実装時に判断が必要になる条件を確認事項に列挙すること」
```

### 3-b. progress.md 生成

```
Task(subagent_type: writer):
  「progress.md を生成してください。
  ドキュメント種別: progress
  feature-name: {feature-name}
  plan.md: docs/plans/{feature-name}/plan.md
  mode: single」
```

---

## Step 4: Annotation Cycle（ブラウザレビュー）

plan.md 生成後、ブラウザでのレビューを提案する。

AskUserQuestion:
- 「ブラウザでレビューする」→ 以下のサイクルを開始
- 「スキップして次へ」→ Step 5 へ

### サイクル

1. **サーバー起動**: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/annotation-viewer/server.py docs/plans/{feature-name}` を実行。既存サーバーがあれば自動的にプラン登録のみ行われる。stdout の `PORT:{port}` からポート取得
2. **ブラウザを開く**: `open http://localhost:{port}`
3. **ファイルポーリングで待機**: 3秒間隔で以下をチェック:
   - **`comments.json` が出現** → plan.md を plan.md.bak にコピー → 読み込み、writer（plan-revision）で plan.md を修正 → comments.json を削除 → 待機に戻る
   - **`review-done.flag` が出現** → 一時ファイルをクリーンアップ → Step 5 へ

---

## Step 5: 完了 + 次のアクション

AskUserQuestion:
- `/build` を実行 — 実装を開始する
- plan.md を修正したい — 修正内容をヒアリングして Step 3 を再実行
- 何もしない — 後で手動で進める
