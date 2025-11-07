//
//  PDFManagerExamples.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import Foundation

/// PDFManager の使用例
class PDFManagerExamples {
    
    // MARK: - 結合の例
    
    /// 複数のPDFを結合する例
    static func exampleMergePDFs() {
        // 入力ファイルのURLを準備
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let inputURLs = [
            documentsURL.appendingPathComponent("./jhs-math2_01-01-02.pdf.pdf"),
            documentsURL.appendingPathComponent("./jhs-math2_01-01-03.pdf.pdf"),
        ]
        
        // 出力先を指定
        let outputURL = documentsURL.appendingPathComponent("Merged.pdf")
        
        // 結合を実行
        do {
            let success = try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
            if success {
                print("✅ PDFの結合に成功しました: \(outputURL.path)")
            }
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 分割の例（1ページずつ）
    
    /// PDFを1ページずつ分割する例
    static func exampleSplitPDF() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 分割するPDFファイル
        let inputURL = documentsURL.appendingPathComponent("Input.pdf")
        
        // 出力先ディレクトリ
        let outputDirectory = documentsURL.appendingPathComponent("SplitPages", isDirectory: true)
        
        // 分割を実行
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
    
    // MARK: - 分割の例（範囲指定）
    
    /// PDFを指定範囲で分割する例
    /// 例: 10ページのPDFを 1-3ページ、4-7ページ、8-10ページ に分割
    static func exampleSplitPDFByRanges() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 分割するPDFファイル
        let inputURL = documentsURL.appendingPathComponent("Input.pdf")
        
        // 出力先ディレクトリ
        let outputDirectory = documentsURL.appendingPathComponent("SplitParts", isDirectory: true)
        
        // ページ範囲を指定（1始まり）
        let pageRanges: [ClosedRange<Int>] = [
            1...3,   // Part-1.pdf: 1-3ページ
            4...7,   // Part-2.pdf: 4-7ページ
            8...10   // Part-3.pdf: 8-10ページ
        ]
        
        // 分割を実行
        do {
            let outputURLs = try PDFManager.splitPDFByRanges(
                inputURL: inputURL,
                pageRanges: pageRanges,
                outputDirectory: outputDirectory,
                fileNamePrefix: "Part"
            )
            print("✅ PDFの分割に成功しました。\(outputURLs.count)個のファイルを作成しました")
            for url in outputURLs {
                print("  - \(url.lastPathComponent)")
            }
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ユーティリティの例
    
    /// ページ数を取得する例
    static func exampleGetPageCount() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsURL.appendingPathComponent("Sample.pdf")
        
        if let pageCount = PDFManager.getPageCount(url: pdfURL) {
            print("📄 \(pdfURL.lastPathComponent) は \(pageCount) ページです")
        } else {
            print("❌ PDFを読み込めませんでした")
        }
    }
    
    // MARK: - 実践的な使用例
    
    /// 複数のPDFを結合し、その後分割する例
    static func exampleMergeAndSplit() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // ステップ1: 複数のPDFを結合
        let inputURLs = [
            documentsURL.appendingPathComponent("Document1.pdf"),
            documentsURL.appendingPathComponent("Document2.pdf")
        ]
        let mergedURL = documentsURL.appendingPathComponent("MergedDocument.pdf")
        
        do {
            // 結合
            _ = try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: mergedURL)
            print("✅ 結合完了: \(mergedURL.lastPathComponent)")
            
            // ページ数を確認
            if let pageCount = PDFManager.getPageCount(url: mergedURL) {
                print("📄 結合後のページ数: \(pageCount)")
            }
            
            // ステップ2: 結合したPDFを1ページずつ分割
            let splitDirectory = documentsURL.appendingPathComponent("SplitOutput", isDirectory: true)
            let splitURLs = try PDFManager.splitPDF(
                inputURL: mergedURL,
                outputDirectory: splitDirectory,
                fileNamePrefix: "Output"
            )
            print("✅ 分割完了: \(splitURLs.count)個のファイルを作成")
            
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
        }
    }
}

// MARK: - 使い方のメモ

/*
 
 ## PDFManager の基本的な使い方
 
 ### 1. PDF結合
 
 ```swift
 let inputURLs = [url1, url2, url3]  // 結合したいPDFのURL配列
 let outputURL = URL(fileURLWithPath: "/path/to/output.pdf")
 
 try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
 ```
 
 ### 2. PDF分割（1ページずつ）
 
 ```swift
 let inputURL = URL(fileURLWithPath: "/path/to/input.pdf")
 let outputDir = URL(fileURLWithPath: "/path/to/output/")
 
 let urls = try PDFManager.splitPDF(
     inputURL: inputURL,
     outputDirectory: outputDir,
     fileNamePrefix: "Page"
 )
 // 結果: Page-1.pdf, Page-2.pdf, Page-3.pdf...
 ```
 
 ### 3. PDF分割（範囲指定）
 
 ```swift
 let inputURL = URL(fileURLWithPath: "/path/to/input.pdf")
 let outputDir = URL(fileURLWithPath: "/path/to/output/")
 let ranges = [1...5, 6...10, 11...15]  // 1-5, 6-10, 11-15ページに分割
 
 let urls = try PDFManager.splitPDFByRanges(
     inputURL: inputURL,
     pageRanges: ranges,
     outputDirectory: outputDir,
     fileNamePrefix: "Part"
 )
 // 結果: Part-1.pdf, Part-2.pdf, Part-3.pdf
 ```
 
 ### 4. ページ数取得
 
 ```swift
 if let count = PDFManager.getPageCount(url: pdfURL) {
     print("ページ数: \(count)")
 }
 ```
 
 */
