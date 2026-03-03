---
title: "feat: README 全面更新（新スキル構成対応）"
feature-name: "readme-update"
status: done
created: 2026-03-03
updated: 2026-03-03
---

# README 全面更新（新スキル構成対応）

## 概要

spec-flow プラグインの開発者・利用者が、現在の4スキル構成（spec / build / check / debug）と循環ワークフロー（spec → build → check → done、NEEDS_FIX 時は spec に戻る）を正確に把握できるよう、README.md と skills/README.md を全面更新する。旧5スキル（plan / strategy / implement / verify / troubleshoot）の記述が残っているため、新しいスキル構成と整合したドキュメントに置き換える必要がある。

## 受入条件

- [ ] AC-1: README.md のワークフロー図が循環型（spec → build → check + debug 独立起動）に更新されている
- [ ] AC-2: README.md のスキル一覧テーブルが新4スキル（spec, build, check, debug）で記載されている
- [ ] AC-3: README.md のスキル詳細セクションが新4スキルの説明に更新されている
- [ ] AC-4: skills/README.md のワークフロー図が新構成に更新されている
- [ ] AC-5: skills/README.md のスキル一覧テーブルが新4スキルで記載されている
- [ ] AC-6: skills/README.md の出力先セクションが新ファイル名（debug-*.md 等）に更新されている
- [ ] AC-7: 旧スキル名（plan, strategy, implement, verify, troubleshoot）への参照が残っていない

## スコープ

### やること

- README.md の全面更新（ワークフロー図、スキル一覧テーブル、スキル詳細セクション、インストール方法）
- skills/README.md の全面更新（ワークフロー図、スキル一覧テーブル、出力先セクション）

### やらないこと

- plugin.json や marketplace.json の更新（既に更新済み）
- スキルやエージェントの SKILL.md / *.md の変更
- 評価フレームワークの変更

## 非機能要件

特になし

## データフロー

本タスクはドキュメント更新のみであり、システム間のデータフローは発生しない。

## 設計判断

| 判断事項 | 選択 | 理由 | 検討した代替案 |
|---------|------|------|--------------|
| ワークフロー図の表現形式 | テキストアート（```ブロック）を使用 | 既存 README のスタイルを踏襲し、Markdown 単体で閲覧可能にする | Mermaid 図 — GitHub 等で自動レンダリングされるが既存スタイルから逸脱 |
| strategy の扱い | 独立スキルとしては記載せず spec に統合されたことを反映 | strategy は spec スキルに統合され廃止されたため、誤解を招く記述を避ける | 廃止スキルとして注記 — かえって混乱を招く可能性がある |
| debug スキルの位置づけ | 循環ワークフローとは独立した任意起動として明示 | debug は spec/build/check の外側から任意タイミングで起動するため | ワークフロー内に組み込む — 実際の動作と乖離する |

## システム影響

### 影響範囲

- README.md（ルートドキュメント。プラグインの顔となる説明ファイル）
- skills/README.md（スキル一覧・ワークフロー・出力先の説明ファイル）

### リスク

- 旧スキル名で検索・ブックマークしているユーザーへの影響 → ドキュメント更新のみのため後方互換性の問題はなし
- 一部の記述が SKILL.md の内容と乖離する可能性 → テスト方針の手動検証で確認

## 実装タスク

### 依存関係図

```mermaid
graph TD
    T1[#1 README.md 更新]
    T2[#2 skills/README.md 更新]
```

### タスク一覧

| # | タスク | 対象ファイル | 見積 | 依存 |
|---|--------|------------|------|------|
| 1 | README.md 更新（ワークフロー図・スキル一覧テーブル・スキル詳細セクション） | `README.md` | S | - |
| 2 | skills/README.md 更新（ワークフロー図・スキル一覧テーブル・出力先セクション） | `skills/README.md` | S | - |

> 見積基準: S(〜1h), M(1-3h), L(3h〜)

## テスト方針

### トレーサビリティ

| 受入条件 | 自動テスト | 手動検証 |
|---------|-----------|---------|
| AC-1 | - | MV-1 |
| AC-2 | - | MV-2 |
| AC-3 | - | MV-3 |
| AC-4 | - | MV-4 |
| AC-5 | - | MV-5 |
| AC-6 | - | MV-6 |
| AC-7 | MV-7（grep） | MV-7 |

### 自動テスト

自動テスト対象なし（ドキュメント更新のみ）。

### ビルド確認

```bash
grep -r "plan\|strategy\|implement\|verify\|troubleshoot" README.md skills/README.md
```

上記コマンドの出力が空であることを確認する（旧スキル名の残存がないこと）。

### 手動検証チェックリスト

- [ ] MV-1: README.md のワークフロー図が循環型（spec → build → check のループ）と debug の独立起動を表現していること
- [ ] MV-2: README.md のスキル一覧テーブルが spec / build / check / debug の4行で構成されていること
- [ ] MV-3: README.md のスキル詳細セクションが spec / build / check / debug の4スキルの説明を含み、旧スキルの説明が削除されていること
- [ ] MV-4: skills/README.md のワークフロー図が新構成（循環型 + debug 独立起動）を表現していること
- [ ] MV-5: skills/README.md のスキル一覧テーブルが spec / build / check / debug の4行で構成されていること
- [ ] MV-6: skills/README.md の出力先セクションに debug-*.md のファイル名が記載されていること
- [ ] MV-7: `grep -r "plan\|strategy\|implement\|verify\|troubleshoot" README.md skills/README.md` の出力が空であること
