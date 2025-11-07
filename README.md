# PDF Palette

macOS用のフローティングPDF操作ツール  
ドラッグ&ドロップで直感的にPDFを結合・分割できるメニューバーアプリケーション

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 特徴

- **Liquid Glass UI**: 美しい透明感のあるフローティングシェルフ
- **グローバルショートカット**: `Option + ;` でどこからでもアクセス(カスタマイズ可能)
- **メニューバー常駐**: Dockを占有せず、必要な時だけ表示
- **ドラッグ&ドロップ**: 直感的な操作でPDFを並べ替え
- **PDF結合・分割**: 複数PDFを1つに、または1ページずつに分割
- **履歴管理**: Undo/Redo対応で安心して操作
- **選択モード**: 複数選択・範囲選択に対応

## インストール

### ダウンロード

[最新リリース](https://github.com/yoppil/PDF-Palette/releases)から `PDF-Palette.dmg` をダウンロード

### インストール手順

1. `PDF-Palette.dmg` をダブルクリック
2. `pdf-palette.app` を `Applications` フォルダにドラッグ
3. アプリケーションフォルダから起動

### 初回起動時の設定

1. **セキュリティ警告が表示された場合**
   - アプリを右クリック（またはControl+クリック）→「開く」
   - または、システム設定 → プライバシーとセキュリティ → 「このまま開く」

2. **アクセシビリティ権限の許可**（グローバルショートカットに必須）
   - システム設定 → プライバシーとセキュリティ → アクセシビリティ
   - `pdf-palette` を有効化
   - アプリを再起動

## 使い方

### 基本操作

1. **シェルフを表示**: `Option + ;` を押す（どのアプリからでも）
2. **PDFを追加**: Finderからシェルフにドラッグ&ドロップ
3. **並べ替え**: PDFをドラッグして順番を変更
4. **結合**: 「Merge」ボタンをクリックして保存先を選択
5. **分割**: PDFを選択して「Split」ボタンをクリック

### ショートカットキー

#### グローバルショートカット
- `Option + ;`: シェルフの表示/非表示（カスタマイズ可能）

#### シェルフ内での操作
- `↑` `↓` `←` `→`: ファイル間の移動
- `Space`: 選択/選択解除
- `Shift + ↑↓`: 複数選択
- `Command + A`: 全選択
- `Command + C`: コピー
- `Command + X`: 切り取り
- `Command + V`: 貼り付け
- `Delete`: 選択したファイルを削除
- `Command + Z`: 元に戻す
- `Command + Shift + Z`: やり直し

### ショートカットのカスタマイズ

1. メニューバーの 📦 アイコンをクリック
2. 「ショートカット設定…」を選択
3. 「ショートカットを変更」をクリック
4. 好きなキーの組み合わせを押す
5. 設定完了！

## 機能詳細

### PDF結合（Merge）

複数のPDFファイルを1つに結合します。

- シェルフ内のPDFの順番が結合時の順番になります
- ドラッグ&ドロップで簡単に順番変更可能
- 結合後のファイル名とページ数を確認できます

### PDF分割（Split）

PDFを個別のファイルに分割します。

**3つの分割モード:**

1. **選択ページのみ**: 選択したページだけを抽出
2. **全体を分割**: すべてのページを1ページずつ分割
3. **分割して結合**: 選択したページを1つのPDFにまとめる

### 複数選択

複数のファイルを同時に操作できます:

- `Command + クリック`: 個別に追加選択
- `Shift + ↑↓`: 範囲選択
- `Command + A`: 全選択

### Undo/Redo

操作を間違えても安心:

- 最大50件の履歴を保持
- ファイルの追加・削除・並べ替えに対応
- `Command + Z` / `Command + Shift + Z` で操作

## ビルド方法（開発者向け）

### 必要な環境

- macOS 12.0+
- Xcode 14.0+
- Swift 5.9+

### ビルド手順

```bash
# リポジトリをクローン
git clone https://github.com/yoppil/PDF-Palette.git
cd PDF-Palette

# Xcodeでプロジェクトを開く
open pdf-palette.xcodeproj

# または、コマンドラインでビルド
xcodebuild -project pdf-palette.xcodeproj \
           -scheme pdf-palette \
           -configuration Release \
           build

# DMGを作成
mkdir -p dist/dmg-contents
cp -R build/Release/pdf-palette.app dist/dmg-contents/
ln -s /Applications dist/dmg-contents/Applications
hdiutil create -volname "PDF Palette" \
               -srcfolder dist/dmg-contents \
               -ov -format UDZO \
               dist/PDF-Palette.dmg
```

## アーキテクチャ

```
pdf-palette/
├── pdf_paletteApp.swift      # アプリケーションエントリーポイント
├── AppDelegate.swift          # メニューバー・ウィンドウ管理
├── ShortcutManager.swift      # グローバルショートカット管理
├── ShortcutSettingsView.swift # ショートカット設定UI
├── ShelfView.swift            # フローティングシェルフUI
├── PDFManager.swift           # PDF操作ロジック
├── PDFMergeView.swift         # PDF結合UI
├── PDFSplitView.swift         # PDF分割UI
├── LiquidGlassView.swift      # Liquid Glassエフェクト
├── HistoryManager.swift       # Undo/Redo管理
└── DropTargetView.swift       # ドラッグ&ドロップ処理
```

## コントリビューション

Issue や Pull Request をお待ちしています！

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

## 謝辞

- SwiftUIとPDFKitを使用して開発
- Liquid GlassデザインはmacOS標準UIから着想

---

Made with by yoppii
