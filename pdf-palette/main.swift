//
//  main.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//
//  コマンドラインから実行するためのエントリーポイント

import Foundation
import PDFKit

print("🎨 PDF Palette - コマンドラインツール")
print("=" + String(repeating: "=", count: 50))

// 使用例: PDF結合
func testMergePDFs() {
    print("\n📦 PDFの結合テスト")
    
    // カレントディレクトリまたは指定パスからPDFを読み込む
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    
    let inputURLs = [
        URL(fileURLWithPath: currentDir + "/A.pdf"),
        URL(fileURLWithPath: currentDir + "/B.pdf")
    ]
    
    let outputURL = URL(fileURLWithPath: currentDir + "/Merged.pdf")
    
    do {
        let success = try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
        if success {
            print("✅ PDFの結合に成功しました: \(outputURL.path)")
        }
    } catch {
        print("❌ エラー: \(error.localizedDescription)")
    }
}

// 使用例: PDF分割
func testSplitPDF() {
    print("\n✂️  PDFの分割テスト")
    
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    
    let inputURL = URL(fileURLWithPath: currentDir + "/A.pdf")
    let outputDirectory = URL(fileURLWithPath: currentDir + "/split_output")
    
    do {
        let outputURLs = try PDFManager.splitPDF(
            inputURL: inputURL,
            outputDirectory: outputDirectory,
            fileNamePrefix: "Page"
        )
        print("✅ PDFの分割に成功しました。\(outputURLs.count)個のファイルを作成しました")
        for url in outputURLs {
            print("  - \(url.lastPathComponent)")
        }
    } catch {
        print("❌ エラー: \(error.localizedDescription)")
    }
}

// コマンドライン引数の処理
let arguments = CommandLine.arguments

if arguments.count < 2 {
    print("\n使用方法:")
    print("  swift run pdf-palette merge     # PDFを結合")
    print("  swift run pdf-palette split     # PDFを分割")
    print("  swift run pdf-palette test      # すべてのテストを実行")
    print("\n引数なしでデフォルトのテストを実行します...\n")
    testMergePDFs()
} else {
    let command = arguments[1]
    
    switch command {
    case "merge":
        testMergePDFs()
    case "split":
        testSplitPDF()
    case "test":
        testMergePDFs()
        testSplitPDF()
    default:
        print("⚠️  不明なコマンド: \(command)")
        print("使用可能なコマンド: merge, split, test")
    }
}

print("\n" + String(repeating: "=", count: 50))
print("✨ 完了")
