## API調査

```
## API パターン

### 技術スタック
- 言語: {判定した言語}
- フレームワーク: {Step 0 で判定したフレームワーク}

### ルーティング
- ルート定義場所: {file paths}
- パターン: {file-based routing, programmatic, etc.}

### 既存エンドポイント
| メソッド | パス | ハンドラファイル | 位置 |
|---------|------|----------------|------|
| {method} | {path} | `{file}` | L{start}-{end} |

### 型定義パターン
- リクエスト型: {how request types are defined}
- レスポンス型: {how response types are defined}
- バリデーション: {検出したバリデーション手法}

### エラーハンドリング
- パターン: {how errors are handled}
- エラー型: {error response format}

### 認証・ミドルウェア
- {auth middleware if any}
```

## DB/スキーマ調査

```
## DB パターン

### スキーマ定義
- ORM: {Step 0 で判定した ORM、または「なし」}
- スキーマファイル: {file path}
- DB種別: {SQLite, PostgreSQL, MySQL, etc.}

### 既存テーブル
| テーブル名 | 主要カラム | リレーション |
|-----------|----------|------------|
| {table} | {columns} | {relations} |

### マイグレーション
- パターン: {how migrations are managed}
- 最新マイグレーション: {latest migration file}

### ID生成
- パターン: {uuid, cuid, auto-increment, ULID, etc.}

### タイムスタンプ
- パターン: {created_at/updated_at の型と形式}
```

## データフロー調査（バックエンド）

```
## バックエンドデータフローパターン

### レイヤー構成
- パターン: {handler → service → repository, etc.}
- 主要なファイル: {file:line のリスト}

### ミドルウェアチェーン
- {middleware list and order}

### 外部サービス連携
- {external APIs, message queues, etc.}

### データの流れ
- {主要なユースケースのバックエンドデータフロー概要}
```

## コンポーネント調査

```
## コンポーネントパターン

### ディレクトリ構成
- コンポーネント配置: {directory structure}
- 命名規則: {PascalCase, kebab-case, etc.}
- ファイル構成: {component + hooks + types per feature, etc.}

### UIライブラリ
- ライブラリ: {検出した UI ライブラリ}
- スタイリング: {Tailwind, CSS Modules, etc.}

### 既存コンポーネントの例
| コンポーネント | ファイル | Props型 | 状態管理 |
|-------------|--------|---------|---------|
| {name} | {file:line} | {props summary} | {hooks used} |

### パターン
- Props定義: {interface vs type, 命名規則}
- 状態管理: {useState, custom hooks, etc.}
- イベントハンドラ: {naming convention}
- フォーム: {library and pattern}
```

## エラーハンドリング・認証パターン調査

```
## エラーハンドリングパターン
- エラー型: {例: AppError extends Error, { code, message, statusCode }} [確認済み]
- レスポンス形式: {例: { error: { code: string, message: string } }} [確認済み]
- 集中ハンドラ: {例: `src/middleware/errorHandler.ts`} [確認済み]
- ログ方針: {例: 400系はWARN、500系はERROR} [確認済み]
※ 見つからない項目は [該当なし] と記載

## 認証・認可パターン
- 認証方式: {例: JWT Bearer token} [確認済み]
- ミドルウェア: {例: `src/middleware/auth.ts`} [確認済み]
- 認可パターン: {例: ensureOwner(req, resource) でリソース所有者チェック} [確認済み]
※ 見つからない項目は [該当なし] と記載
```

## データフロー調査（フロントエンド）

```
## フロントエンドデータフローパターン

### API通信
- HTTPクライアント: {検出したライブラリ}
- パターン: {fetch wrapper, custom hooks, etc.}
- 主要なAPI呼び出し箇所: {file:line のリスト}

### 状態管理
- ライブラリ: {検出した状態管理手法}
- グローバルステート: {主要なstore/contextのリスト}
- パターン: {provider配置、カスタムフック等}

### データの流れ
- {主要なユースケースのフロントエンドデータフロー概要}
```
