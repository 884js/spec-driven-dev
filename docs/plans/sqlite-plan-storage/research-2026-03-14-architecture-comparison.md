# リサーチ: SQLite データストア — MCP サーバー型 vs Bash スクリプト型の比較

調査日: 2026-03-14
調査タイプ: 外部技術

## 調査ゴール

SQLite をデータストアにする場合の 2 つのアーキテクチャ（MCP サーバー型 / Bash スクリプト型）を詳細に比較し、どちらが spec-driven-dev プラグインに適しているか判断する。

## 選択肢の比較

### 総合比較

| 観点 | MCP サーバー型 | Bash スクリプト型 |
|------|---------------|-----------------|
| 自由記述テキストの安全性 | JSON-RPC で自動エスケープ。問題なし | Base64 エンコードで回避可能だが DB 内が読めなくなる |
| SQL インジェクション対策 | パラメータ化クエリ（prepared statement）使用可能 | CLI に真の prepared statement なし。エスケープ関数で対応 |
| スキル .md からの呼び出し | `mcp__server__tool_name` で自然に呼び出し | `Bash "scripts/db.sh get-plan foo"` で呼び出し |
| 実装言語 | TypeScript or Python | Bash + sqlite3 CLI |
| 初期開発コスト | 高（MCP SDK 学習 + サーバー実装） | 中（Bash スクリプト実装） |
| 保守コスト | 中（SDK バージョン追従） | 低（Bash + sqlite3 は安定） |
| ビルドステップ | TypeScript の場合 tsc が必要 | なし |
| 依存関係 | `@modelcontextprotocol/sdk`, `zod`, `better-sqlite3` | macOS 標準の sqlite3 のみ |
| 起動コスト | セッション開始時にプロセス起動（数百ms） | 各コマンド実行時にプロセス起動（数十ms） |
| 常駐メモリ | Node.js プロセス常駐（~50MB） | 非常駐 |
| 型安全性 | Zod スキーマで入出力を定義可能 | なし |
| テスト | Jest / Vitest で構造化テスト可能 | BATS で可能だが表現力は限定的 |
| 配布方法 | `.mcp.json` に定義、プラグインに同梱可 | scripts/ ディレクトリに同梱 |
| Git 運用 | DB は .gitignore、スキーマ SQL + サーバーコードをバージョン管理 | DB は .gitignore、スキーマ SQL + スクリプトをバージョン管理 |

### アーキテクチャ詳細

#### MCP サーバー型

```
┌─────────────┐     JSON-RPC (stdio)     ┌──────────────────┐
│ スキル .md   │ ◄──────────────────────► │ MCP サーバー      │
│ (Claude)     │   mcp__store__get_plan   │ (Node.js)        │
│              │   mcp__store__set_status │                  │
└─────────────┘                          │  better-sqlite3  │
                                         │  ┌────────────┐  │
                                         │  │ store.db   │  │
                                         │  └────────────┘  │
                                         └──────────────────┘
```

- **ツール定義例**:
  - `get_plan(feature_name)` → plan のメタデータ + 本文を返す
  - `list_plans(status_filter?)` → 全プランの一覧をステータス付きで返す
  - `update_task_status(feature_name, task_id, status)` → タスク状態を更新
  - `get_related_plans(feature_name)` → 関連プランを FK 経由で取得
  - `set_plan_body(feature_name, body)` → Markdown 本文を格納

- **Markdown 本文の受け渡し**: JSON-RPC のパラメータとして文字列を渡すため、改行・特殊文字は JSON シリアライズで自動エスケープ。Bash の二重エスケープ問題は発生しない

- **プラグイン同梱の設定** (`.mcp.json`):
  ```json
  {
    "mcpServers": {
      "spec-store": {
        "command": "node",
        "args": ["${CLAUDE_PLUGIN_ROOT}/servers/spec-store/dist/index.js"],
        "env": { "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data/store.db" }
      }
    }
  }
  ```

- **既存実装**: Anthropic 公式 `mcp-server-sqlite` はアーカイブ済み + SQL インジェクション脆弱性あり。自前実装が必要

#### Bash スクリプト型

```
┌─────────────┐     Bash ツール          ┌──────────────────┐
│ スキル .md   │ ──────────────────────► │ scripts/db.sh    │
│ (Claude)     │  "scripts/db.sh         │ (Bash)           │
│              │   get-plan foo"         │                  │
└─────────────┘                          │  sqlite3 CLI     │
                                         │  ┌────────────┐  │
                                         │  │ store.db   │  │
                                         │  └────────────┘  │
                                         └──────────────────┘
```

- **サブコマンド例**:
  - `db.sh get-plan <feature>` → JSON 形式でプラン情報を返す
  - `db.sh list-plans [--status=X]` → 全プラン一覧
  - `db.sh update-status <feature> <status>` → ステータス更新
  - `db.sh set-body <feature> < plan.md` → stdin から Markdown を読み込み Base64 で格納
  - `db.sh get-body <feature>` → Base64 デコードして Markdown を出力

- **Markdown 本文の格納**: Base64 エンコードで安全に格納。ただし DB を直接確認する際に本文が読めない

- **SQL インジェクション対策**: sqlite3 CLI には prepared statement がないため、シングルクォートエスケープ関数 `escape_sql()` で対応。ただし Base64 済みテキストはシングルクォートを含まないので安全

- **マイグレーション**: `PRAGMA user_version` + `migrations/0001_*.sql` パターンで管理

### 決定的な差異

#### 1. 自由記述テキストの扱い（MCP が圧倒的に有利）

MCP サーバー型では JSON-RPC のパラメータとして Markdown テキストを直接受け渡しでき、エスケープ処理は SDK が自動で行う。サーバー側では `better-sqlite3` のパラメータバインディング（`db.prepare("INSERT INTO plans (body) VALUES (?)").run(body)`）でそのまま格納できる。

Bash 型では Base64 エンコード/デコードのレイヤーが必須で、DB 内のデータが人間に読めなくなるトレードオフがある。

#### 2. スキル .md での呼び出しの自然さ（MCP がやや有利）

```markdown
# MCP 型: スキルから自然にツールとして呼べる
allowed-tools:
  - mcp__spec-store__get_plan
  - mcp__spec-store__list_plans

# Bash 型: Bash コマンドとして呼ぶ
Bash: scripts/db.sh get-plan my-feature
```

MCP 型は Claude がツールとして認識するため、パラメータの型チェックや説明文が活きる。Bash 型はコマンド文字列を組み立てる必要がある。

#### 3. 初期開発コスト（Bash が有利）

MCP サーバーは TypeScript プロジェクトのセットアップ、SDK 学習、ビルドパイプラインの構築が必要。Bash スクリプトは即座に書き始められる。

#### 4. 長期保守性（MCP がやや有利）

MCP 型は型安全で、テストも構造化しやすい。Bash 型はロジックが複雑化すると保守が困難になる（複数のコメントが「複雑になったら Python/Go に移行せよ」と指摘）。

## 推奨・結論

**MCP サーバー型を推奨する。**

理由:
1. **自由記述テキスト問題の根本解決**: JSON-RPC + パラメータバインディングで、Bash の二重エスケープ問題が存在しない。これが最初の調査で「致命的」と判定した最大の障壁を解消する
2. **スキルとの自然な統合**: MCP ツールは Claude のツール呼び出しとして扱われ、型付きパラメータ・説明文が活きる
3. **このプロジェクトが Claude Code プラグインである**: MCP サーバーの同梱は `.mcp.json` で自然にサポートされており、プラグインのアーキテクチャと整合する
4. **長期的な拡張性**: リレーション管理、集計クエリ、検索機能の追加が SQL + 型安全な API で容易

初期コストは高いが、プロジェクトの性質（Claude Code プラグイン開発ツール）を考えると、MCP サーバーの知見がそのまま他のスキル開発にも活きる。

### 想定スキーマ（概要）

```sql
CREATE TABLE plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feature_name TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft',
  body TEXT,  -- plan.md の本文
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER REFERENCES plans(id),
  task_number INTEGER NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',  -- pending/in_progress/done
  UNIQUE(plan_id, task_number)
);

CREATE TABLE plan_relations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_plan_id INTEGER REFERENCES plans(id),
  target_plan_id INTEGER REFERENCES plans(id),
  relation_type TEXT,  -- 'depends_on', 'related', 'conflicts'
  description TEXT,
  UNIQUE(source_plan_id, target_plan_id)
);

CREATE TABLE results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER REFERENCES plans(id),
  judgment TEXT NOT NULL,  -- PASS/PARTIAL/NEEDS_FIX
  body TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE research (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER REFERENCES plans(id),
  topic TEXT NOT NULL,
  body TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
```

## 次のステップ

1. MCP サーバーの PoC 実装（最小限のツール: `list_plans`, `get_plan`, `create_plan`）
2. 既存の /list スキルを MCP ツール経由に書き換えて速度・体験を検証
3. 問題なければ段階的に他のスキルも移行

## 出典

- [Build an MCP server - Model Context Protocol](https://modelcontextprotocol.io/docs/develop/build-server)
- [modelcontextprotocol/typescript-sdk - GitHub](https://github.com/modelcontextprotocol/typescript-sdk)
- [mcp-server-sqlite - PyPI](https://pypi.org/project/mcp-server-sqlite/)
- [Claude Code MCP Docs](https://code.claude.com/docs/en/mcp)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [SQLite Command Line Shell](https://sqlite.org/cli.html)
- [SQLite Write-Ahead Logging](https://sqlite.org/wal.html)
- [SQLite DB Migrations with PRAGMA user_version](https://levlaz.org/sqlite-db-migrations-with-pragma-user_version/)
- [BATS-core: Writing Tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html)
- [Understanding JSON-RPC Protocol in MCP](https://mcpcat.io/guides/understanding-json-rpc-protocol-mcp/)
