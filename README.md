# PDF Palette 🎨

macOS用のPDF操作ツール（結合・分割）

## VS Codeでの実行方法 ✅

### 方法1: ターミナルから直接実行（簡単・推奨）

```bash
# PDFを結合
./run.sh merge

# PDFを分割
./run.sh split

# 全テスト実行
./run.sh test
```

### 方法2: VS Codeのタスクを使用

1. `Cmd + Shift + P` でコマンドパレットを開く
2. "Tasks: Run Task" を選択
3. 以下から選択：
   - **PDF結合テスト**
   - **PDF分割テスト**
   - **全テスト実行**

または、`Cmd + Shift + B` でデフォルトタスク（全テスト実行）を実行

**✨ Finderは開きません！ターミナルで完結します。**

## 機能

### ✅ PDF結合 (Merge)
複数のPDFファイルを1つに結合します。

```swift
let inputURLs = [url1, url2, url3]
try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
```

### ✂️ PDF分割 (Split)
PDFを1ページずつ個別のファイルに分割します。

```swift
let urls = try PDFManager.splitPDF(
    inputURL: inputURL,
    outputDirectory: outputDir,
    fileNamePrefix: "Page"
)
```

### 📄 範囲指定分割
指定したページ範囲でPDFを分割します。

```swift
let ranges = [1...5, 6...10]  // 1-5ページと6-10ページに分割
let urls = try PDFManager.splitPDFByRanges(
    inputURL: inputURL,
    pageRanges: ranges,
    outputDirectory: outputDir
)
```

## テスト用PDFの準備

以下のディレクトリ構造でPDFファイルを配置してください：

```
pdf-palette/
├── input/              # 入力PDFを配置
│   ├── A.pdf
│   └── B.pdf
├── merged_output/      # 結合結果の出力先
│   └── Merged.pdf      (自動生成)
└── split_output/       # 分割結果の出力先
    └── Page-*.pdf      (自動生成)
```

**入力ファイル:** `input/` ディレクトリに配置
**結合出力:** `merged_output/` に生成
**分割出力:** `split_output/` に生成

## Xcodeでの実行

GUIアプリとして実行する場合：

```bash
open pdf-palette.xcodeproj
```

Xcodeで開いて実行すると、macOSのネイティブアプリとして起動します。

## なぜFinderが開くのか？

現在の `pdf_paletteApp.swift` は `DocumentGroup` を使用しているため、
ファイルを開く/保存するFinderダイアログが表示されます。

これはmacOSのドキュメントベースアプリの標準動作です。

### 2つの実行方法：

1. **コマンドライン** (`main.swift`) 
   → Finderなし、ターミナルで完結
   → VS Codeから実行可能

2. **GUIアプリ** (`pdf_paletteApp.swift`)
   → Finderダイアログあり、ユーザーフレンドリー
   → Xcodeから実行

## 開発環境

- macOS 12.0+
- Swift 5.9+
- PDFKit

## ライセンス

MIT
