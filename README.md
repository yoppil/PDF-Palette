# PDF Palette

A floating PDF manipulation tool for macOS  
Intuitively merge and split PDFs with drag & drop in a menu bar application

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Liquid Glass UI**: Beautiful transparent floating shelf
- **Global Shortcuts**: Access from anywhere with `Option + ;` (customizable)
- **Menu Bar App**: Doesn't occupy Dock space, appears only when needed
- **Drag & Drop**: Intuitive PDF reordering
- **Merge & Split**: Combine multiple PDFs or split into individual pages
- **History Management**: Undo/Redo support for worry-free operation
- **Selection Modes**: Multiple selection and range selection support

## Installation

### Download

Download `PDF-Palette.dmg` from [Latest Release](https://github.com/yoppil/PDF-Palette/releases)

### Installation Steps

1. Double-click `PDF-Palette.dmg`
2. Drag `pdf-palette.app` to the `Applications` folder
3. Launch from Applications folder

### First Launch Setup

1. **If Security Warning Appears**
   - Right-click (or Control+click) the app → "Open"
   - Or, System Settings → Privacy & Security → "Open Anyway"

2. **Grant Accessibility Permissions** (Required for global shortcuts)
   - System Settings → Privacy & Security → Accessibility
   - Enable `pdf-palette`
   - Restart the app

## Usage

## Usage

### Basic Operations

1. **Show Shelf**: Press `Option + ;` (from any app)
2. **Add PDFs**: Drag & drop from Finder to the shelf
3. **Reorder**: Drag PDFs to change their order
4. **Merge**: Click "Merge" button and select save location
5. **Split**: Select a PDF and click "Split" button

### Keyboard Shortcuts

#### Global Shortcuts

- `Option + ;`: Show/hide shelf (customizable)

#### Operations Within Shelf

- `↑` `↓` `←` `→`: Navigate between files
- `Space`: Select/deselect
- `Shift + ↑↓`: Multiple selection
- `Command + A`: Select all
- `Command + C`: Copy
- `Command + X`: Cut
- `Command + V`: Paste
- `Delete`: Remove selected files
- `Command + Z`: Undo
- `Command + Shift + Z`: Redo

### Customizing Shortcuts

1. Click the menu bar icon
2. Select "Shortcut Settings..."
3. Click "Change Shortcut"
4. Press your desired key combination
5. Done!

## Features

### PDF Merge

Combine multiple PDF files into one.

- The order of PDFs in the shelf determines the merge order
- Easy reordering with drag & drop
- Preview file name and page count after merging

### PDF Split

Split PDFs into individual files.

**3 Split Modes:**

1. **Selected Pages Only**: Extract only selected pages
2. **Split All**: Split all pages into individual files
3. **Split and Merge**: Combine selected pages into one PDF

### Multiple Selection

Operate on multiple files simultaneously:

- `Command + Click`: Add individual selections
- `Shift + ↑↓`: Range selection
- `Command + A`: Select all

### Undo/Redo

Safe operation even if you make mistakes:

- Keeps up to 50 history entries
- Supports file add/remove/reorder operations
- `Command + Z` / `Command + Shift + Z` to operate

## Build Instructions (For Developers)

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

## Build Instructions (For Developers)

### Requirements

- macOS 12.0+
- Xcode 14.0+
- Swift 5.9+

### Build Steps

```bash
# Clone the repository
git clone https://github.com/yoppil/PDF-Palette.git
cd PDF-Palette

# Open project in Xcode
open pdf-palette.xcodeproj

# Or build from command line
xcodebuild -project pdf-palette.xcodeproj \
           -scheme pdf-palette \
           -configuration Release \
           build

# Create DMG
mkdir -p dist/dmg-contents
cp -R build/Release/pdf-palette.app dist/dmg-contents/
ln -s /Applications dist/dmg-contents/Applications
hdiutil create -volname "PDF Palette" \
               -srcfolder dist/dmg-contents \
               -ov -format UDZO \
               dist/PDF-Palette.dmg
```

## Architecture

```
pdf-palette/
├── pdf_paletteApp.swift      # Application entry point
├── AppDelegate.swift          # Menu bar & window management
├── ShortcutManager.swift      # Global shortcut management
├── ShortcutSettingsView.swift # Shortcut settings UI
├── ShelfView.swift            # Floating shelf UI
├── PDFManager.swift           # PDF operation logic
├── PDFMergeView.swift         # PDF merge UI
├── PDFSplitView.swift         # PDF split UI
├── LiquidGlassView.swift      # Liquid Glass effect
├── HistoryManager.swift       # Undo/Redo management
└── DropTargetView.swift       # Drag & drop handling
```

## Contributing

Issues and Pull Requests are welcome!

## License

MIT License - See [LICENSE](LICENSE) for details

## Acknowledgments

- Built with SwiftUI and PDFKit
- Liquid Glass design inspired by macOS standard UI

---

Made with by yoppii
