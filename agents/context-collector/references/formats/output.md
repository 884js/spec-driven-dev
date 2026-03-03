以下の形式で構造化された要約を返すこと:

```
## プロジェクト概要
- プロジェクト名: {name}
- プロジェクトパス: {pwd の結果}
- 説明: {description from CLAUDE.md or package.json}

## 技術スタック
### フロントエンド ({リポジトリ名 or ディレクトリ名})
- フレームワーク: {framework + version (e.g. Next.js 14, React 18)}
- 言語: {language + version (e.g. TypeScript 5.x)}
- UIライブラリ: {ui library (e.g. shadcn/ui, MUI, Chakra UI, なし)}
- 状態管理: {state management (e.g. React Query, Zustand, Redux, なし)}
- テスト: {test framework (e.g. Vitest, Jest, なし)}

### バックエンド ({リポジトリ名 or ディレクトリ名})
- フレームワーク: {framework + version (e.g. Gin 1.9, Express 4.x)}
- 言語: {language + version (e.g. Go 1.22, Node.js 20)}
- ORM: {orm (e.g. GORM, Prisma, SQLAlchemy, なし)}
- DB: {db (e.g. PostgreSQL 15, MySQL 8, SQLite)}
- テスト: {test framework (e.g. go test, Jest, pytest)}

※ フロントエンド/バックエンドが同一リポジトリの場合もセクションを分ける。
  片方しか存在しない場合は該当セクションのみ記載。

## フレームワーク制約
- {フレームワーク} {バージョン}: {ルーティング方式、推奨パターン}
- 設定: {主要な設定内容（strict mode、module system 等）}
- 非推奨/注意: {あれば記載、なければ「なし」}

## アーキテクチャパターン
### バックエンド
- アーキテクチャ: {例: クリーンアーキテクチャ Controllers -> Usecases -> Repository -> Models}
- コントローラーパターン: {例: シングルアクションコントローラー（1コントローラー = 1メソッド）}
- DI: {例: go-fx、各層で module.go に Module 定義}
- エラーハンドリング: {例: xerrors.Errorf(": %w", err) でラップ}
- リポジトリ構成: {例: new.go, entity.go, read.go, create.go, update.go, delete.go, module.go}

### フロントエンド
- ディレクトリパターン: {例: Features Directory パターン}
- コンポーネント配置: {例: [名前]/index.tsx + index.stories.tsx + index.test.tsx}
- 型定義の生成元: {例: @openapi/* から自動生成}

※ 実際のコードから観測したパターンを具体例付きで記載する。
  該当パターンがない項目は省略可。

## ディレクトリ構成
- 主要ディレクトリ: {dirs with brief description}
- エントリポイント: {main entry files}
- ルーティング: {routing pattern if applicable}

## データベース
- DB種別: {db type (e.g. PostgreSQL, SQLite, D1)}
- ORM: {orm (e.g. Prisma, Drizzle, GORM, SQLAlchemy, none)}
- マイグレーション: {migration tool (e.g. prisma migrate, goose, alembic, none)}
- スキーマファイル: `{path}`
- マイグレーションディレクトリ: `{path}`

### 主要テーブル（関連するもの）
- {table_name}: {brief description}
  - カラム: {column1}, {column2}, {column3}, ...
  - リレーション: {他テーブルとの関係（例: users has_many posts, posts belongs_to user）}
  - 命名パターン: {例: boolean系は is_xxx / has_xxx / xxx_enabled}

※ 機能概要が渡されている場合は、関連テーブルを優先的に調査する。
  テーブル数が多い場合は関連性の高いもの最大5テーブルに絞る。

## 既存の型定義
- `{path}`: {主要な型の列挙}
- `{path}`: {主要な型の列挙}

## 開発コマンド
- dev: {dev command}
- build: {build command}
- test: {test command}
- lint: {lint command}

## コーディング規約
- {conventions from CLAUDE.md}
- {conventions from AGENTS.md}

## 既存仕様書
- `{path}`: {spec summary}
※ なければ「なし」

## 過去の教訓（関連するもの）
- `{path}`: {タイトル} — {関連ポイント}
※ なければ「なし」

## 関連する既存機能
- {機能名}: {概要}
  - テーブル: {table names}
  - コントローラー: {controller paths}
  - ユースケース: {usecase paths}

※ 機能概要が渡されている場合のみ記載する。
  渡されていない場合はこのセクション自体を省略する。

## 調査ソース
- 規約: `CLAUDE.md`, `AGENTS.md`
- マニフェスト: `{path}`
- スキーマ: `{path}`
- 型定義: `{path}`, `{path}`, ...
- 既存仕様書: `{path}`

※ 実際に Read して情報を取得したファイルのみ記載する。
```
