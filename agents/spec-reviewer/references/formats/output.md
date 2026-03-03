```
## レビュー結果

### 判定: PASS / NEEDS_FIX

### 問題点（NEEDS_FIX の場合）
| # | 重要度 | セクション | 問題 | 修正案 |
|---|--------|----------|------|-------|
| 1 | HIGH   | {section} | {issue description} | {specific fix suggestion} |

### 良い点
- {specific positive aspects}

### サマリー
- チェック項目: {n}
- PASS: {n}
- NEEDS_FIX: {n}
```

**重要度の基準**:
- **CRITICAL**: セクション間で矛盾がある（APIで定義した型がDB型と不一致等）
- **HIGH**: 参照が欠落している（実装タスクに設計で言及したファイルが含まれていない等）
- **MEDIUM**: テストや影響範囲の網羅性が不十分
- **LOW**: 命名の不統一、軽微なフォーマット崩れ

**判定基準**:
- **PASS**: CRITICAL と HIGH が 0 件
- **NEEDS_FIX**: CRITICAL または HIGH が 1 件以上
