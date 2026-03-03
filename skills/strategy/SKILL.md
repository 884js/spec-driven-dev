---
name: strategy
description: "Generates progress.md with delivery plan and task tracking. Analyzes plan.md tasks, proposes PR grouping, delivery order, and risk assessment through user dialogue. Use when planning PR splitting or delivery strategy."
allowed-tools: Read Glob Grep Edit Write Task AskUserQuestion
metadata:
  triggers: strategy, delivery plan, PR分割, デリバリー戦略, 実装戦略, PR splitting
---

# 実装戦略（Strategy）

plan.md の実装タスク表を分析し、**PR分割・デリバリー順序・リスク判断** をユーザーとの対話で決定する。
plan（何を作るか）と implement（作る）の間にある「**どう分けて届けるか**」を担うフェーズ。

入力: `docs/plans/{feature-name}/plan.md`（実装タスク表が含まれていること）
出力: `docs/plans/{feature-name}/progress.md`（タスク進捗テーブル。multi-pr の場合はデリバリープランも含む）

**重要**: plan.md は **読み取り専用**。一切変更しない。

**パスルール**: `docs/plans/{feature-name}/` はカレントディレクトリ直下。`{feature-name}` は英語の kebab-case（例: `campaign-notification`）。パス区切り不可

## ワークフロー

```
Step 1: plan.md 読み込み
Step 2: 分割案の自動生成（判断基準に基づく）
Step 3: ユーザーと対話で分割を確定
Step 4: progress.md を新規作成（タスク進捗 + デリバリープラン）
```

---

## Step 1: plan.md 読み込み

スキル起動直後に、既存のドキュメントを読み込む:

```
Glob docs/plans/**/plan.md
```

$ARGUMENTS に feature-name が指定されている場合はそのディレクトリを使用。
plan.md が1つだけの場合はそのまま使用。

複数の plan.md が見つかった場合は AskUserQuestion で選択させる:
- 各 plan.md のパスと feature 名を選択肢として提示
- 例: 「docs/plans/user-auth/plan.md」「docs/plans/search/plan.md」

```
Read docs/plans/{feature-name}/plan.md
```

plan.md が存在しない場合は「先に `/plan` で設計・実装計画を作成してください」と案内して終了する。

plan.md の `status` が `planning` の場合は「plan.md がまだ作成中です。先に `/plan` を完了してください」と案内して終了する。

### feature-state.json のガード

Read docs/plans/{feature-name}/feature-state.json
- plan.status が "done" でなければ「先に /plan を完了してください」と案内して終了。
- feature-state.json が存在しない場合は、plan.md の frontmatter status で代替判定。

既に `docs/plans/{feature-name}/progress.md` が存在する場合は、その内容を表示し「progress.md を再作成しますか？」と確認する。

---

## Step 2: 分割案の自動生成

plan.md の実装タスク表を分析し、以下の判断基準で分割案を生成する。

### 分割の判断基準

| 条件 | 分割方針 |
|------|---------|
| タスク数 5個以下 & 見積合計が S-M 中心 | 1 PR（分割不要を提案） |
| レイヤーが明確に分離（DB/API/UI） | レイヤー単位で分割 |
| 独立した機能スライスがある | 機能スライス単位 |
| リスクの高いタスクがある | 高リスク部分を独立PR化 |
| 新規テーブル（CREATE TABLE） | DB変更を先行PR化 |
| 既存テーブル変更（ALTER TABLE） | 新規テーブルとは別PRに分離（後方互換性リスクが異なるため） |
| 1つの PR に L サイズが 3個以上 | PR が肥大化している。分割を検討する |

### 分析プロセス

1. **タスク一覧の抽出**: 実装タスク表から全タスクを読み取る
2. **依存関係の把握**: 依存関係図（Mermaid）からタスク間の依存を理解する
3. **レイヤー分類**: 各タスクの対象ファイルからレイヤー（DB/API/UI/共通）を判定
4. **タスクレベルのリスク評価**: 各タスクのリスクを個別に判定する（リスク判定基準を参照）
5. **グルーピング**: 判断基準に照らしてPR単位を決定。1 PR あたりの L タスク数が 3 以上にならないよう注意する
6. **高リスク PR の軽減策検討**: 高リスクと判定した PR について、具体的なリスク軽減策を検討する

### リスク判定基準

| リスクレベル | 条件 |
|------------|------|
| 低 | 見積 S-M、既存パターン踏襲、影響範囲が限定的 |
| 中 | 見積 L、新しいパターン導入、複数モジュールに影響、新規テーブル作成（CREATE TABLE） |
| 高 | 既存テーブル変更（ALTER TABLE）、認証・認可変更、外部API連携、後方互換性への影響、Webhook/非同期処理、既存フローの修正 |

タスクごとのリスクも判定する。これは Step 2 の分析時に内部的に行い、Step 3 の提示で高リスクタスクを明示する。

---

## Step 3: ユーザーとの対話

分割案をユーザーに提示し、フィードバックを受けて確定する。

### 提示形式

```
plan.md を分析しました。以下の分割案を提案します:

PR1: {PRタイトル}
  タスク: #{タスク番号}, #{タスク番号}
  リスク: {低/中/高}

PR2: {PRタイトル}
  タスク: #{タスク番号}, #{タスク番号}
  依存: PR1
  リスク: {低/中/高}

⚠️ 高リスクタスク:
- #{番号} {タスク名}: {リスク要因}（例: 既存テーブル変更、外部API連携）

分割の理由:
- {なぜこの分割にしたかの説明}

この分割で進めますか？変更したい場合は修正内容を教えてください。
```

高リスクタスクがない場合は「⚠️ 高リスクタスク」セクションを省略する。

### 分割不要の場合

```
plan.md を分析しました。

タスク数: {N}個、見積合計: {サイズ分布}
→ 1 PR で十分な規模です。分割せずに進めることを提案します。

この方針で進めますか？それとも分割しますか？
```

- ユーザーが承認 → Step 4 へ（single モードで progress.md を作成）
- ユーザーが分割を希望 → 分割案を提示（提示形式に従う）

分割不要の場合も、single モードの progress.md を作成してから `/feature-spec:implement` を案内する（→ Step 4）。

### 対話ルール

- ユーザーが分割案を承認 → Step 4 へ（multi-pr モード）
- ユーザーが修正を要求 → 修正案を再提示
- ユーザーが「分割不要」と判断、または最初から分割不要 → Step 4 へ（single モード）

---

## Step 4: progress.md の作成

ユーザーが方針を確定したら、`docs/plans/{feature-name}/progress.md` を Write で新規作成する。
分割不要（single）の場合も、分割あり（multi-pr）の場合も、常に progress.md を作成する。

**plan.md は一切変更しない**（読み取り専用）。

### 4-a. single モード（分割不要）の場合

plan.md の実装タスク表を読み取り、状態列を付与して progress.md に記述する。PR 列・デリバリープランは不要。

```
Task(subagent_type: strategy-writer):
  プロンプト: 「progress.md を生成してください。
  feature-name: {feature-name}
  plan.md: docs/plans/{feature-name}/plan.md
  mode: single」
```

### 4-b. multi-pr モード（分割あり）の場合

plan.md の実装タスク表を読み取り、PR 列と状態列を付与して progress.md に記述する。

plan.md のタスク表:
```markdown
| # | タスク | 対象ファイル | 見積 |
```

↓ progress.md のタスク進捗テーブル（高リスクタスクがある場合はリスク列を付与）:
```markdown
| # | タスク | 対象ファイル | 見積 | PR | リスク | 状態 |
|---|-------|------------|------|-----|--------|------|
| 1 | スキーマ定義 | `schema.ts` | S | PR1 | 低 | - |
| 2 | API実装 | `handler.ts` | M | PR1 | 低 | - |
| 3 | 既存テーブル変更 | `migration.sql` | S | PR1 | **高** | - |
| 4 | UI実装 | `Form.tsx` | L | PR2 | 中 | - |
```

全タスクが低リスクの場合はリスク列を省略してよい。高リスクタスクが1つでもある場合はリスク列を付与する。

デリバリープランセクションも記述する。

```
Task(subagent_type: strategy-writer):
  プロンプト: 「progress.md を生成してください。
  feature-name: {feature-name}
  plan.md: docs/plans/{feature-name}/plan.md
  mode: multi-pr
  PR グルーピング:
    {確定した分割内容をここに記述}」
```

### 4-c. 完了

feature-state.json を更新する:

```
Task(subagent_type: feature-state-manager, run_in_background: true):
  プロンプト: 「feature-state.json を更新してください。
  パス: docs/plans/{feature-name}/feature-state.json
  更新内容:
    strategy.status = "done"
    strategy.references = ["./progress.md"]
    phase = "strategized"」
```

```
progress.md を作成しました。

次のステップ:
- 実装に進む場合は `/implement` を使用してください
- plan.md を修正したい場合は直接編集してください
```
