#!/bin/bash

# PDF Palette 実行スクリプト

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

COMMAND="${1:-test}"

echo "🎨 PDF Palette - コマンドラインツール"
echo "=================================================="
echo ""

# Swiftコードを直接実行
swift - "$COMMAND" <<'SWIFT_CODE'
import Foundation
import PDFKit

// PDFManager のコード
class PDFManager {
    static func mergePDFs(inputURLs: [URL], outputURL: URL) throws -> Bool {
        guard !inputURLs.isEmpty else {
            throw PDFError.noInputFiles
        }
        
        let mergedPDF = PDFDocument()
        var currentPageIndex = 0
        
        for inputURL in inputURLs {
            guard let pdfDocument = PDFDocument(url: inputURL) else {
                throw PDFError.cannotOpenFile(inputURL.lastPathComponent)
            }
            
            for pageIndex in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    mergedPDF.insert(page, at: currentPageIndex)
                    currentPageIndex += 1
                }
            }
        }
        
        guard mergedPDF.write(to: outputURL) else {
            throw PDFError.cannotWriteFile(outputURL.lastPathComponent)
        }
        
        return true
    }
    
    static func splitPDF(inputURL: URL, outputDirectory: URL, fileNamePrefix: String = "Page") throws -> [URL] {
        guard let pdfDocument = PDFDocument(url: inputURL) else {
            throw PDFError.cannotOpenFile(inputURL.lastPathComponent)
        }
        
        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            throw PDFError.emptyDocument
        }
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectory.path) {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }
        
        var outputURLs: [URL] = []
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            
            let singlePagePDF = PDFDocument()
            singlePagePDF.insert(page, at: 0)
            
            let pageNumber = pageIndex + 1
            let fileName = String(format: "%@-%d.pdf", fileNamePrefix, pageNumber)
            let outputURL = outputDirectory.appendingPathComponent(fileName)
            
            guard singlePagePDF.write(to: outputURL) else {
                throw PDFError.cannotWriteFile(fileName)
            }
            
            outputURLs.append(outputURL)
        }
        
        return outputURLs
    }
    
    static func getPageCount(url: URL) -> Int? {
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }
        return pdfDocument.pageCount
    }
}

enum PDFError: LocalizedError {
    case noInputFiles
    case cannotOpenFile(String)
    case cannotWriteFile(String)
    case emptyDocument
    
    var errorDescription: String? {
        switch self {
        case .noInputFiles:
            return "入力ファイルが指定されていません"
        case .cannotOpenFile(let fileName):
            return "ファイル '\(fileName)' を開けません"
        case .cannotWriteFile(let fileName):
            return "ファイル '\(fileName)' を書き込めません"
        case .emptyDocument:
            return "PDFドキュメントが空です"
        }
    }
}

// メイン処理
func testMergePDFs() {
    print("📦 PDFの結合テスト")
    
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    
    let inputURLs = [
        URL(fileURLWithPath: currentDir + "/input/A.pdf"),
        URL(fileURLWithPath: currentDir + "/input/B.pdf")
    ]
    
    let outputURL = URL(fileURLWithPath: currentDir + "/merged_output/Merged.pdf")
    
    do {
        let success = try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
        if success {
            print("✅ PDFの結合に成功しました: \(outputURL.path)")
            if let pageCount = PDFManager.getPageCount(url: outputURL) {
                print("   ページ数: \(pageCount)")
            }
        }
    } catch {
        print("❌ エラー: \(error.localizedDescription)")
    }
}

func testSplitPDF() {
    print("\n✂️  PDFの分割テスト")
    
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    
    let inputURL = URL(fileURLWithPath: currentDir + "/input/A.pdf")
    let outputDirectory = URL(fileURLWithPath: currentDir + "/split_output")
    
    do {
        let outputURLs = try PDFManager.splitPDF(
            inputURL: inputURL,
            outputDirectory: outputDirectory,
            fileNamePrefix: "Page"
        )
        print("✅ PDFの分割に成功しました。\(outputURLs.count)個のファイルを作成しました")
        for url in outputURLs {
            print("   - \(url.lastPathComponent)")
        }
    } catch {
        print("❌ エラー: \(error.localizedDescription)")
    }
}

// コマンド実行
let command = CommandLine.arguments[1]

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

print("\n==================================================")
print("✨ 完了")
SWIFT_CODE
