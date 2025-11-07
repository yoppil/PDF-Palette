# VS Codeでの実行について

## なぜFinderが開くのか？

これは **Xcodeプロジェクト（macOSアプリ）** だからです。

- `pdf_paletteApp.swift` は `DocumentGroup` を使用
- GUIアプリとして起動し、ファイルを開く/保存するダイアログを表示
- これはmacOSのドキュメントベースアプリの標準動作

## 解決方法：2つの実行モード

### 1. コマンドラインモード（VS Code向け）✅

**`run.sh`** を使用すると、Finderなしで実行できます！

```bash
./run.sh merge   # PDF結合
./run.sh split   # PDF分割
./run.sh test    # 全テスト
```

**特徴:**
- ✅ Finderは開きません
- ✅ ターミナルで完結
- ✅ VS Codeから実行可能
- ✅ 自動化・バッチ処理に最適

**VS Codeでの実行:**
- `Cmd + Shift + B` → 全テスト実行
- または `Cmd + Shift + P` → "Tasks: Run Task" → タスクを選択

### 2. GUIアプリモード（Xcode向け）

**Xcodeで実行** すると、macOSのネイティブアプリとして起動します。

```bash
open pdf-palette.xcodeproj
```

**特徴:**
- 📂 Finderダイアログが開く
- 🖱️ ユーザーフレンドリー
- 🎨 GUI操作

## 実行結果の例

```bash
$ ./run.sh test
🎨 PDF Palette - コマンドラインツール
==================================================

📦 PDFの結合テスト
✅ PDFの結合に成功しました: /Users/yoppii/code/pdf-palette/Merged.pdf
   ページ数: 2

✂️  PDFの分割テスト
✅ PDFの分割に成功しました。1個のファイルを作成しました
   - Page-1.pdf

==================================================
✨ 完了
```

## ファイル構成

```
pdf-palette/
├── run.sh                      # ← コマンドライン実行スクリプト（VS Code用）
├── pdf-palette/
│   ├── PDFManager.swift        # ← コアロジック
│   ├── main.swift              # ← コマンドラインエントリーポイント
│   └── pdf_paletteApp.swift   # ← GUIアプリエントリーポイント（Xcode用）
├── .vscode/
│   └── tasks.json              # ← VS Codeタスク定義
├── A.pdf                       # テスト用入力
├── B.pdf                       # テスト用入力
├── Merged.pdf                  # 結合結果
└── split_output/               # 分割結果
    └── Page-1.pdf
```

## まとめ

| 実行方法 | Finder | 向いている用途 |
|---------|--------|--------------|
| `run.sh` (コマンドライン) | ❌ 開かない | VS Code、自動化、開発中 |
| Xcode (GUIアプリ) | ✅ 開く | エンドユーザー向け配布 |

**VS Codeで開発する場合は `run.sh` を使いましょう！**
