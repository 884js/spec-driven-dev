# リサーチ: MCP サーバー追加によるトークン消費増加の問題

調査日: 2026-03-14
調査タイプ: 外部技術

## 調査ゴール

MCP サーバーを追加すると Claude Code のトークン消費がどれだけ増えるか、精度への影響、対策を明らかにする。

## 調査結果

### トークン消費の仕組み

Claude Code は起動時に有効な全 MCP ツールの定義（名前・説明文・パラメータスキーマ）をコンテキストウィンドウに一括ロードする。ツールを使う・使わないに関わらず毎回発生する。

### 実測値

| 構成 | トークン消費 | コンテキスト消費率 (200k) |
|------|------------|----------------------|
| 組み込みツールのみ | 約 10,000〜16,600 | 約 8% |
| MCP 4 サーバー追加 | 約 15,000〜20,000 | 約 10% |
| MCP 7 サーバー追加 | 約 67,300 | 約 33.7% |
| MCP 5 サーバー・58 ツール | 約 55,000 | 約 27.5% |
| GitHub MCP 単体 | 約 46,000 | 約 23% |
| 最悪ケース（複数サーバー） | 約 98,700〜144,802 | 約 49〜72% |

→ **MCP サーバー 1 つ追加で数千〜数万トークンが固定消費される**

### 精度への影響

ツール数が 10〜20 を超えると:
- LLM がツール選択を誤りやすくなる
- 類似ツール名を hallucinate する事例がある
- ツール結果を注意深く読まずに仮定で応答するケースが増加

Anthropic 内部テスト（MCP Tool Search 導入前後）:

| モデル | Tool Search なし | Tool Search あり |
|--------|----------------|----------------|
| Opus 4 | 49.0% | 74.0% |
| Opus 4.5 | 79.5% | 88.1% |

### 対策: MCP Tool Search（Claude Code 組み込み機能）

MCP ツール定義がコンテキストの 10% を超えると自動起動する。ツール定義を事前ロードせず、必要時に検索するオンデマンド方式。

- **トークン削減効果: 約 85%**（77,000 → 8,700 トークン）
- `ENABLE_TOOL_SEARCH` 環境変数で制御可能
  - `auto`（デフォルト）: 10% 超過時に自動有効化
  - `auto:5`: 5% 超過時
  - `true`: 常に有効
  - `false`: 無効
- Sonnet 4 / Opus 4 以降で動作。Haiku は非対応

### SQLite MCP サーバー案への影響

仮に spec-store MCP サーバーを作った場合:
- ツール数が 5〜10 程度なら数千トークンの増加
- 既に他の MCP サーバー（Notion, freee など）を使っている場合、累積で圧迫する
- **Tool Search が有効なら問題は大幅に緩和される**が、deferred tools として扱われるためツール呼び出しに1ステップ追加される

### Bash スクリプト型との比較（トークン観点）

| 観点 | MCP サーバー型 | Bash スクリプト型 |
|------|---------------|-----------------|
| 固定トークン消費 | ツール定義分（数千トークン） | なし（Bash ツール自体は組み込み） |
| ツール呼び出し時 | MCP ツール呼び出し + レスポンス | Bash コマンド + 出力 |
| Tool Search 時 | deferred → 検索 → 呼び出しの 2 ステップ | 直接呼び出し |

→ **トークン消費の観点では Bash スクリプト型が明確に有利**

## 推奨・結論

トークン消費の観点を加味すると、**Bash スクリプト型の優位性がさらに高まる**。

- MCP サーバーを追加するとツール定義だけで固定トークンが増える
- 既に Notion MCP や freee MCP を使っている環境では累積効果が大きい
- Tool Search で緩和されるが、完全には解消されない
- Bash スクリプト型なら追加のトークン消費はゼロ

## 出典

- [Optimising MCP Server Context Usage in Claude Code - Scott Spence](https://scottspence.com/posts/optimising-mcp-server-context-usage-in-claude-code)
- [MCP tools consume 50% of context tokens - Issue #13717](https://github.com/anthropics/claude-code/issues/13717)
- [Built-in tools + MCP descriptions load causing 10-20k token overhead - Issue #3406](https://github.com/anthropics/claude-code/issues/3406)
- [Connect Claude Code to tools via MCP - Claude Code 公式ドキュメント](https://code.claude.com/docs/en/mcp)
- [What is MCP Tool Search? - atcyrus.com](https://www.atcyrus.com/stories/mcp-tool-search-claude-code-context-pollution-guide)
- [Claude Code's Hidden MCP Flag - paddo.dev](https://paddo.dev/blog/claude-code-hidden-mcp-flag/)
