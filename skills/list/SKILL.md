---
name: list
description: "Displays all plans under docs/plans/ with status information and lets the user select a plan to edit, build, research, or check. Use as a hub for navigating existing plans."
allowed-tools: Read Glob Grep AskUserQuestion Skill
metadata:
  triggers: list, plans, プラン一覧, 一覧表示, プラン管理
---

# プラン一覧（List）

`docs/plans/` 配下のプラン一覧をステータス付きで表示し、アクション選択のハブとして機能する。

## ワークフロー

```
Step 1: プラン走査 + ステータス表示
Step 2: プラン選択 + アクション選択
```

---

## Step 1: プラン走査 + ステータス表示

```
Glob docs/plans/**/plan.md
```

0件なら「プランが見つかりません。`/spec` で新規作成してください。」と案内して終了。

各プランの plan.md（title, feature-name）、progress.md（タスク状態）、result.md（judgment）を読み、ステータスを算出する:

| 条件 | ステータス |
|------|-----------|
| result.md あり → judgment 値 | `検証済み` / `部分合格` / `要修正` |
| progress.md のタスクに `→` あり | `実装中` |
| progress.md のタスクが全て `✓` | `実装完了` |
| progress.md あり、全て `-` | `未着手` |
| plan.md のみ | `仕様作成済み` |

番号付きリストでステータスと共に表示する。

---

## Step 2: プラン選択 + アクション選択

AskUserQuestion でプランを選択させ、続けてアクションを選択させる:
- 仕様を編集する → `Skill(spec, args: "{feature-name}")` で起動
- 実装する → `Skill(build, args: "{feature-name}")` で起動
- 検証する → `Skill(check, args: "{feature-name}")` で起動
