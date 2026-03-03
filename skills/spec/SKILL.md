---
name: spec
description: "Generates or updates plan.md through requirements hearing, integrated analysis, and design dialogue. Handles both new spec creation and update mode (from check results). Includes PR split planning for large features. Use when starting a new feature or updating an existing spec."
allowed-tools: Read Glob Grep Edit Task AskUserQuestion
metadata:
  triggers: spec, plan, create spec, new spec, design, requirements, update spec, 仕様書作成, 要件定義, 仕様更新
---

# 仕様作成（Spec）

ユーザーの要求から plan.md を生成するスキル。既存の plan.md がある場合は更新モードに切り替える。
大規模機能では PR 分割付きの progress.md も同時生成する。

入力: ユーザーの要求（$ARGUMENTS または対話）
出力: `docs/plans/{feature-name}/plan.md`（+ progress.md for 大規模機能）

**パスルール**: `docs/plans/{feature-name}/` はカレントディレクトリ直下。`{feature-name}` は英語の kebab-case。パス区切り不可

## ワークフロー

```
Step 0: モード判定（新規 / 更新）
Step 1: 要件ヒアリング
Step 2: 統合分析（analyzer）
Step 3: ソリューション設計（ハイブリッド対話）
Step 4: plan.md 生成 + 自己検証（writer）
Step 5: state.json 更新 + 次のアクション提示
```

---

## Step 0: モード判定

```
Glob docs/plans/**/plan.md
```

$ARGUMENTS に feature-name が指定されている場合はそのディレクトリを使用。

- **plan.md が存在しない** → **新規モード**: Step 1 へ
- **plan.md が存在する** → **更新モード**: Step 0-b へ

### 0-b. 更新モードの初期化

```
Read docs/plans/{feature-name}/plan.md
Read docs/plans/{feature-name}/state.json
```

check 結果（result.md）があれば読み込む:
```
Glob docs/plans/{feature-name}/result.md
```

result.md が存在する場合、NEEDS_FIX の不一致箇所を抽出してユーザーに提示する。
ユーザーに変更点をヒアリングした上で Step 3 へ（統合分析はスキップ）。

---

## Step 1: 要件ヒアリング

### 1-a. 初期ヒアリング

$ARGUMENTS が渡されている場合は初期要求として扱い、不明点があれば AskUserQuestion で確認する。

$ARGUMENTS がない場合は AskUserQuestion で確認する:
- どんな機能を追加したいか（ユーザーストーリー）
- 何ができたら完成か（受入条件）
- スコープ外にすることはあるか
- 非機能要件（特にない場合はスキップ可）

1-2往復で明確になったら次へ。

### 1-b. 規模判定

ヒアリング結果から規模を判定する:
- **小**: タスク3未満
- **中**: タスク3-7
- **大**: タスク8以上

大規模の場合は分割案を提示する:
```
この機能は規模が大きいため、分割を提案します:
Phase 1: {機能名A}
Phase 2: {機能名B}
分割して進めますか？
```

---

## Step 2: 統合分析（analyzer）

analyzer エージェントにプロジェクトの統合分析を依頼する:

```
Task(subagent_type: analyzer):
  プロンプト: 「このプロジェクトの統合分析を行ってください。
  CLAUDE.md、ディレクトリ構造、依存関係、型定義、DBスキーマ、既存仕様書、
  コードパターン（API、DB、コンポーネント、データフロー）、Git履歴を調査し、
  1つの統合レポートで返してください。
  追加機能の概要: {Step 1 で把握した機能概要}」
```

### 並行開発チェック

```
Glob docs/plans/**/plan.md
```

他の仕様書が存在する場合、変更対象ファイルの重複を確認し、重複があればユーザーに報告する。

---

## Step 3: ソリューション設計（ハイブリッド）

analyzer の結果を踏まえ、データフロー + 各ドメインの設計案を一気に提示する。

### 3-a. 省略判定

要件とデータフローをもとに必要なドメインを判定:
- **バックエンド**: 新規/変更のAPIエンドポイントがない場合は省略
- **DB**: テーブルの新規作成・カラム追加が不要な場合は省略
- **フロントエンド**: UI変更がない場合は省略

### 3-b. 設計案の一括提示

analyzer で把握した既存パターン・命名規則に従い、以下を一度に提示する:

1. **データフロー**: Mermaid sequenceDiagram（ラベルは自然言語）
2. **バックエンド設計**: 操作・入出力・エラーケースを自然言語で記述
3. **DB設計**: テーブルごとに目的・関係・カラム一覧
4. **フロントエンド設計**: 画面・操作・表示データ + ワイヤーフレーム
5. **設計判断**: 主要な技術選択の理由と代替案

**plan.md の粒度ルール**:
- コード（型定義、SQL、コンポーネント実装）は一切含めない
- 全ての設計を自然言語で記述する

### 3-c. レビュー対話

ユーザーの指摘に対して修正。確認が取れたら Step 4 へ。

---

## Step 4: plan.md 生成 + 自己検証（writer）

### 4-a. plan.md 生成

writer エージェントに生成を委譲する:

```
Task(subagent_type: writer):
  プロンプト: 「docs/plans/{feature-name}/plan.md を生成してください。
  ドキュメント種別: plan
  プロジェクト規約: {analyzer の要約}
  設計内容:
    概要: {確定した要件}
    受入条件: {確定した受入条件}
    スコープ: {確定したスコープ}
    データフロー: {確定したシーケンス図}
    バックエンド: {確定したAPI設計}
    DB: {確定したDB設計}
    フロントエンド: {確定したフロントエンド設計}
    設計判断: {記録した設計判断}
    影響範囲: {把握した影響}
    実装タスク: {依存関係付きタスク一覧}
    テスト方針: {テスト一覧・チェックリスト・ビルドコマンド}
  注意:
  - frontmatter の status は done にすること
  - plan.md は機能仕様書。コードは一切含めない
  - 自己検証でセクション間の整合性を確認すること」
```

### 4-b. 大規模機能の progress.md 生成

規模判定が「大」の場合、PR 分割付きの progress.md も同時生成する:

```
Task(subagent_type: writer):
  プロンプト: 「progress.md を生成してください。
  ドキュメント種別: progress
  feature-name: {feature-name}
  plan.md: docs/plans/{feature-name}/plan.md
  mode: multi-pr
  PR グルーピング: {Step 3 で決定した PR 分割}」
```

---

## Step 5: 完了 + 次のアクション

### state.json の更新

新規モードの場合、state.json を生成する。phase を "spec"、spec.status を "in_progress" に設定し、完了時に spec.status を "done"、phase を "build" に設定する。

更新モードの場合、spec.status を "done" に更新する。

### 次のアクション提示

AskUserQuestion で次のアクションを選択させる:
- `/build` を実行 — 実装を開始する
- 何もしない — 後で手動で進める
