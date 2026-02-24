---
name: implement
description: "Use when starting implementation based on a completed plan. Invoke for feature branch creation, task-by-task coding guided by plan.md, testing, and PR creation. Supports pause/resume via task state tracking. 実装開始, 開発開始, コーディング."
allowed-tools: Read, Glob, Grep, Write, Edit, Task, Bash
metadata:
  triggers: implement, start coding, 実装開始, 開発開始, コーディング開始, start implementation
---

# 実装（Implement）

plan.md が完成した後、**plan.md に沿って実装を進める**。
ブランチ作成 → タスク順の実装 → ビルド確認 → PR 作成 までを一貫してガイドする。
**タスク状態列による中断・再開** をサポートする。

入力: `docs/{feature-name}/plan.md`
出力: 実装コード + PR

**パスルール**: `docs/{feature-name}/` はカレントディレクトリ直下。`{feature-name}` は日本語のシンプルな名前（パス区切り不可）

仕様の修正が必要な場合は `/feature-spec:revise` で行う。

## タスク状態管理

plan.md の実装タスク表の **状態列** でタスクの進捗を管理する:

| 記号 | 意味 |
|------|------|
| `-` | 未着手 |
| `→` | 実施中 |
| `✓` | 完了 |

## ワークフロー

```
Step 0: plan.md 読み込み + 再開検知
Step 1: feature ブランチ作成（新規開始時のみ）
Step 2: タスク順の実装（plan.md のタスク表に沿って）
Step 3: ビルド確認（plan.md のビルド確認セクションを実行）
Step 4: PR 作成（ユーザー確認後）
```

---

## Step 0: 読み込み + 再開検知

スキル起動直後に、既存のドキュメントを読み込む:

```
Glob docs/**/plan.md
```

$ARGUMENTS に feature-name が指定されている場合はそのディレクトリを使用。
複数の仕様書ディレクトリがある場合はユーザーに選択を求める。

**project-context.md の鮮度チェック**:
`docs/{feature-name}/project-context.md` の先頭数行を Read し、生成日を確認:
- 生成日から7日以上経過している場合: 「project-context.md が {N}日前の情報です。差分更新を行いますか？」と提案
- 更新する場合: context-collector を差分更新モードで起動

```
Read docs/{feature-name}/plan.md
```

plan.md が存在しない場合は「先に `/feature-spec:plan` で設計・実装計画を作成してください」と案内して終了する。

### 再開検知

plan.md の実装タスク表の状態列をチェック:

- **全て `-`** → **新規開始**: Step 1（ブランチ作成）に進む
- **`✓` や `→` あり** → **再開フロー**:

```
前回の実装状態を検出しました:

| # | タスク | 状態 |
|---|-------|------|
| 1 | {タスク名} | ✓ 完了 |
| 2 | {タスク名} | ✓ 完了 |
| 3 | {タスク名} | → 実施中 |
| 4 | {タスク名} | - 未着手 |

進捗: {完了数}/{全数} タスク
```

再開時の追加チェック:
- `git diff --name-only` でアドホック変更（plan.md のタスクに含まれない変更）がないか検知
- アドホック変更がある場合はユーザーに報告

AskUserQuestion で再開ポイントを確認:
- 「`→` のタスク #{N} から再開する」
- 「次の未着手タスク #{M} から始める」
- 「全体を確認し直す」

---

## Step 1: feature ブランチ作成

docs ディレクトリ名（日本語）と plan.md の内容から、適切な英語のブランチ名を提案する。

**ブランチ名の規則**:
- 形式: `feature/{english-name}`
- 例: `docs/リマインダー/` → `feature/reminder`

```
ブランチ名: feature/{english-name}

この名前で作成しますか？（変更する場合は希望のブランチ名を入力してください）
```

**ブランチ作成**:
- ユーザー確認後、`git checkout -b feature/{english-name}` で作成
- 同名ブランチが既に存在する場合: 「既存ブランチに切り替える」or「別名で作成」を AskUserQuestion で選択

**ステータス更新**:
- ブランチ作成後、plan.md の frontmatter `status` を `implementing` に Edit で更新

---

## Step 2: タスク順の実装（サブエージェント委譲パターン）

plan.md の「実装タスク」表を依存関係順に処理する。
**各タスクは code-researcher サブエージェントで調査 → メインコンテキストで実装** のハイブリッドで進める。

### タスク状態の更新

各タスクの開始時と完了時に plan.md の状態列を Edit で更新する:
- 開始: `-` → `→`
- 完了: `→` → `✓`

### 各タスクの進め方

```
── タスク #{N}: {タスク名} ({見積}) ──

1. plan.md の状態列を `→` に更新

2. Task(code-researcher) を起動:
   プロンプト:
   「タスク #{N}（{タスク名}）の実装に必要な情報を収集してください。
   仕様書: docs/{feature-name}/plan.md の該当セクション
   プロジェクト規約: docs/{feature-name}/project-context.md
   既存コード: {対象ファイル一覧}（存在する場合）
   以下を要約して返してください:
   - 実装に必要な型定義・インターフェース
   - 既存コードのパターン（命名規則、ディレクトリ構造）
   - バリデーションルール、エラーハンドリング
   - テストパターン」

3. code-researcher の調査結果をもとに実装

4. 完了後、plan.md の状態列を `✓` に更新
```

**仕様書の参照ルール**（code-researcher に渡すセクションの判定）:
- タスク名やファイルパスから該当するセクションを判定:
  - DB/スキーマ関連 → plan.md の「DB変更」セクション
  - API/エンドポイント関連 → plan.md の「バックエンド変更」セクション
  - UI/コンポーネント関連 → plan.md の「フロントエンド変更」セクション
  - 型定義 → 複数のセクションを横断参照
- **メインコンテキストでは plan.md を直接 Read しない**（Step 0 で読み込み済み）。code-researcher が読み、要約を返す。

**見積サイズに応じた戦略**:
- **S（小）**: code-researcher で調査 → 直接実装。実装後にまとめて確認。
- **M（中）**: code-researcher で調査 → 直接実装。主要な判断ポイントで確認。
- **L（大）**: code-researcher で調査 → 実装方針をユーザーに提示 → 承認後に直接実装。

**タスク間の確認**:
- 各タスク完了後: 「タスク #{N} が完了しました。次のタスク #{N+1} に進みますか？」
- ユーザーが修正を求めた場合はその場で対応

**仕様矛盾検知プロトコル**:
仕様書の内容と実際のコードで矛盾が見つかった場合:
1. 矛盾の内容をユーザーに提示し、選択肢を提示:
   a) `/feature-spec:revise` で仕様修正 → 現在のタスク番号を記録し、修正後に再開
   b) 実装側を仕様に合わせる
   c) このまま進めて後で対応（plan.md のフィードバックログに記録）

---

## Step 3: ビルド確認

plan.md の「ビルド確認」セクションに記載されたコマンドを順に実行する。

```
ビルド確認を実行します（plan.md より）:

✓ {コマンド1}  # {説明}
✓ {コマンド2}  # {説明}
✗ {コマンド3}  # {説明} ← エラーがあれば内容を提示
✓ {コマンド4}  # {説明}
```

**エラー時の対応**:
- エラー内容を提示し、該当箇所を修正
- 修正後にそのコマンドを再実行して確認
- 全コマンドが通るまで繰り返す

**手動検証チェックリストの提示**:
- plan.md の「手動検証チェックリスト」セクションをユーザーに提示:

```
手動検証チェックリスト（plan.md より）:
- [ ] {チェック項目1}
- [ ] {チェック項目2}

手動検証が完了したら、PR 作成に進みますか？
```

---

## Step 4: PR 作成

ユーザー確認後、`gh pr create` で PR を作成する。

**PR タイトル**:
```
{plan.md の title フィールドから取得}
```

**PR 本文の生成**:

1. リポジトリの PR テンプレートを探す:
   ```
   Glob .github/pull_request_template.md
   Glob .github/PULL_REQUEST_TEMPLATE/*.md
   ```
2. テンプレートが見つかった場合: テンプレートの構造に従い、plan.md の情報で各セクションを埋める
3. テンプレートがない場合: plan.md の概要・影響範囲・テスト方針をもとにシンプルな PR 本文を生成

**PR 作成の流れ**:

1. PR タイトルと本文をユーザーに提示して確認
2. 未コミットの変更があればコミットを提案（ユーザー確認必須 — CLAUDE.md ルール）
3. `git push -u origin feature/{english-name}`
4. `gh pr create --title "..." --body "..."`
5. PR の URL をユーザーに提示

```
PR を作成しました: {PR URL}
```

**ステータス更新**:
- PR 作成後、plan.md の frontmatter `status` を `done` に Edit で更新

---

## Step 4.5: 仕様検証（任意）

実装完了後、仕様との整合性を確認する場合は `/feature-spec:verify` を使用してください。

---

## Step 5: PRフィードバック対応ガイド

PR作成後にレビュー指摘やQA不具合が発生した場合の対応フロー:

| 分類 | 例 | 対応 |
|------|-----|------|
| 実装バグ | ロジックミス | コード修正 → 追加コミット |
| 仕様不足 | エッジケース漏れ | `/feature-spec:revise` → 実装修正 |
| 仕様変更 | 要件自体の変更 | `/feature-spec:revise` → 実装修正 |
| 設計見直し | アーキテクチャ指摘 | `/feature-spec:revise` → 再実装 |

**対応手順**:
1. 指摘内容を分類し、対応方針をユーザーに提示
2. 仕様修正が必要な場合は `/feature-spec:revise` を案内
3. 修正後は Step 3（ビルド確認）から再実行
4. 追加コミット → PR 更新
