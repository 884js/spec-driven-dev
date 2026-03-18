---
name: check
description: "Verifies plan-code alignment. Pre-build: checks if plan assumptions still hold against current codebase (GO / UPDATE_NEEDED / BLOCKED). Post-build: verifies implementation matches spec (PASS / PARTIAL / NEEDS_FIX). Use after selecting a plan or after build completion."
allowed-tools: Read Glob Grep Write Task Bash
metadata:
  triggers: check, verify, validate, preflight, 仕様検証, 実装確認, 受入条件チェック, 実現性確認
---

# プラン検証（Check）

プランとコードの整合性を検証する。タスク状態で自動的にモードを切り替える。

- **Pre-build**（全タスク pending）: プランの前提が現在のコードで成り立つか検証
- **Post-build**（タスク進行中/完了）: 実装が仕様通りか突合検証

入力: DB 上の plan レコード + コードベース
出力: Pre-build は判定のみ。Post-build は DB 上の result レコード

**feature-name**: 英語の kebab-case

## ワークフロー

```
Step 0: 読み込み + モード判定
  ├─ 全タスク pending → Pre-build フロー（Step P1〜P2）
  └─ それ以外 → Post-build フロー（Step 1〜3）
```

---

## Step 0: 読み込み + モード判定

```
Bash "${CLAUDE_PLUGIN_ROOT}/scripts/db.sh get-body --feature {feature-name}"
Bash "${CLAUDE_PLUGIN_ROOT}/scripts/db.sh list-tasks --feature {feature-name}"
```

全タスク `pending` → **Pre-build フロー**へ。それ以外 → **Post-build フロー**（Step 1）へ。

---

## Pre-build フロー

### Step P1: コードベースとの乖離分析

plan の `updated_at` 以降のコード変更を確認し、プランの前提が崩れていないか検証する:

```
Task(subagent_type: analyzer):
  「このプランの実現性を検証してください。
  DB スクリプト: ${CLAUDE_PLUGIN_ROOT}/scripts/db.sh
  feature-name: {feature-name}
  検証観点:
  - プランが触る予定のファイル・関数・APIに、プラン作成後の変更が入っていないか
  - プランが依存するライブラリ・スキーマ・型定義が現在も存在し互換性があるか
  - プランの設計方針と矛盾する変更が他で入っていないか
  - プランの設計アプローチ自体が現在のコードベースに対して妥当か（新たに確立されたパターンや追加された機能との整合性）」
```

### Step P2: 判定 + 次のアクション

| 判定 | 基準 |
|------|------|
| **GO** | 前提に影響する変更なし。そのまま build 可能 |
| **UPDATE_NEEDED** | 前提の一部が変化。プラン修正を推奨 |
| **BLOCKED** | 前提が根本的に崩れている。プラン再設計が必要 |

- **GO**: 「プランは現在のコードと整合しています。`/build` で実装を開始できます。」
- **UPDATE_NEEDED**: 乖離箇所を列挙し、AskUserQuestion で `/spec`（プラン更新）か `/build`（そのまま進行）かを選択させる
- **BLOCKED**: 乖離箇所を列挙し、`/spec` でのプラン再設計を案内する

---

## Post-build フロー

### Step 1: verifier で突合検証

```
Bash: git diff {base-branch} --name-only
```

verifier に仕様・実装・受入条件の突合を一括で依頼する:

```
Task(subagent_type: verifier):
  「仕様と実装の突合検証を行ってください。
  DB スクリプト: ${CLAUDE_PLUGIN_ROOT}/scripts/db.sh
  feature-name: {feature-name}
  実装ファイル: {git diff の変更ファイル一覧}
  検証内容:
  - 各セクション（バックエンド・DB・フロントエンド等）の仕様と実装の突合
  - データフロー図がある場合は処理フローの突合
  - 受入条件の充足確認
  - 仕様で指定されたファイルの作成・変更の確認」
```

---

### Step 2: 最終判定 + result 生成

| 判定 | 基準 |
|------|------|
| **PASS** | Critical 0件 & Warning 0件 |
| **PARTIAL** | Critical 0件、Warning のみ |
| **NEEDS_FIX** | Critical 1件以上 |

```
Task(subagent_type: writer):
  「result を DB に生成してください。
  ドキュメント種別: result
  DB スクリプト: ${CLAUDE_PLUGIN_ROOT}/scripts/db.sh
  feature-name: {feature-name}
  verifier 結果: {Step 1 の結果}
  judgment: {最終判定}」
```

---

### Step 3: 次のアクション

- **PASS**: 「検証完了。PR のマージに進めます。」
- **PARTIAL**: 不一致一覧を提示し、実装修正か仕様修正かを選択させる
- **NEEDS_FIX**: 不一致箇所を列挙し提案:
  - 実装漏れ → `/build` で修正
  - 仕様不足 → `/spec` で仕様更新
