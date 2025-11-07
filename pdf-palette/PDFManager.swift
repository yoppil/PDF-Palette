//
//  PDFManager.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import Foundation
import PDFKit

/// PDFの結合・分割を行うマネージャークラス
class PDFManager {
    
    // MARK: - PDF結合
    
    /// 複数のPDFファイルを1つに結合する
    /// - Parameters:
    ///   - inputURLs: 結合するPDFファイルのURL配列（結合する順番）
    ///   - outputURL: 出力先のURL
    /// - Returns: 成功した場合true、失敗した場合false
    /// - Throws: ファイル操作に関するエラー
    static func mergePDFs(inputURLs: [URL], outputURL: URL) throws -> Bool {
        // 空の場合はエラー
        guard !inputURLs.isEmpty else {
            throw PDFError.noInputFiles
        }
        
        // 新しい空のPDFDocumentを作成
        let mergedPDF = PDFDocument()
        var currentPageIndex = 0
        
        // 各PDFファイルを順番に処理
        for inputURL in inputURLs {
            // PDFファイルを読み込み
            guard let pdfDocument = PDFDocument(url: inputURL) else {
                throw PDFError.cannotOpenFile(inputURL.lastPathComponent)
            }
            
            // 全ページを取得して結合先PDFに追加
            for pageIndex in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    mergedPDF.insert(page, at: currentPageIndex)
                    currentPageIndex += 1
                }
            }
        }
        
        // 結果を保存
        guard mergedPDF.write(to: outputURL) else {
            throw PDFError.cannotWriteFile(outputURL.lastPathComponent)
        }
        
        return true
    }
    
    // MARK: - PDF分割
    
    /// PDFファイルを1ページずつ分割する
    /// - Parameters:
    ///   - inputURL: 分割するPDFファイルのURL
    ///   - outputDirectory: 出力先ディレクトリのURL
    ///   - fileNamePrefix: 出力ファイル名のプレフィックス（例: "Output"）
    /// - Returns: 作成されたファイルのURL配列
    /// - Throws: ファイル操作に関するエラー
    static func splitPDF(inputURL: URL, outputDirectory: URL, fileNamePrefix: String = "Page") throws -> [URL] {
        // PDFファイルを読み込み
        guard let pdfDocument = PDFDocument(url: inputURL) else {
            throw PDFError.cannotOpenFile(inputURL.lastPathComponent)
        }
        
        // ページ数を取得
        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            throw PDFError.emptyDocument
        }
        
        // 出力ディレクトリが存在しない場合は作成
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectory.path) {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }
        
        var outputURLs: [URL] = []
        
        // 各ページを個別のPDFとして保存
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            
            // 新しいPDFDocumentを作成
            let singlePagePDF = PDFDocument()
            singlePagePDF.insert(page, at: 0)
            
            // ファイル名を生成（例: Page-1.pdf, Page-2.pdf...）
            let pageNumber = pageIndex + 1
            let fileName = String(format: "%@-%d.pdf", fileNamePrefix, pageNumber)
            let outputURL = outputDirectory.appendingPathComponent(fileName)
            
            // ファイルに保存
            guard singlePagePDF.write(to: outputURL) else {
                throw PDFError.cannotWriteFile(fileName)
            }
            
            outputURLs.append(outputURL)
        }
        
        return outputURLs
    }
    
    // MARK: - PDF範囲分割
    
    /// PDFファイルを指定ページ範囲で分割する
    /// - Parameters:
    ///   - inputURL: 分割するPDFファイルのURL
    ///   - pageRanges: ページ範囲の配列（例: [1...3, 4...6] で1-3ページと4-6ページに分割）
    ///   - outputDirectory: 出力先ディレクトリのURL
    ///   - fileNamePrefix: 出力ファイル名のプレフィックス
    /// - Returns: 作成されたファイルのURL配列
    /// - Throws: ファイル操作に関するエラー
    static func splitPDFByRanges(inputURL: URL, pageRanges: [ClosedRange<Int>], outputDirectory: URL, fileNamePrefix: String = "Part") throws -> [URL] {
        // PDFファイルを読み込み
        guard let pdfDocument = PDFDocument(url: inputURL) else {
            throw PDFError.cannotOpenFile(inputURL.lastPathComponent)
        }
        
        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            throw PDFError.emptyDocument
        }
        
        // 出力ディレクトリが存在しない場合は作成
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectory.path) {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }
        
        var outputURLs: [URL] = []
        
        // 各範囲ごとに処理
        for (rangeIndex, range) in pageRanges.enumerated() {
            let newPDF = PDFDocument()
            var insertIndex = 0
            
            // 範囲内のページを追加
            for pageNumber in range {
                // ページ番号は1始まりだが、インデックスは0始まり
                let pageIndex = pageNumber - 1
                
                // 範囲チェック
                guard pageIndex >= 0 && pageIndex < pageCount else {
                    continue
                }
                
                if let page = pdfDocument.page(at: pageIndex) {
                    newPDF.insert(page, at: insertIndex)
                    insertIndex += 1
                }
            }
            
            // ページが追加された場合のみ保存
            if newPDF.pageCount > 0 {
                let fileName = String(format: "%@-%d.pdf", fileNamePrefix, rangeIndex + 1)
                let outputURL = outputDirectory.appendingPathComponent(fileName)
                
                guard newPDF.write(to: outputURL) else {
                    throw PDFError.cannotWriteFile(fileName)
                }
                
                outputURLs.append(outputURL)
            }
        }
        
        return outputURLs
    }
    
    // MARK: - ユーティリティ
    
    /// PDFのページ数を取得する
    /// - Parameter url: PDFファイルのURL
    /// - Returns: ページ数、読み込めない場合はnil
    static func getPageCount(url: URL) -> Int? {
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }
        return pdfDocument.pageCount
    }
}

// MARK: - エラー定義

enum PDFError: LocalizedError {
    case noInputFiles
    case cannotOpenFile(String)
    case cannotWriteFile(String)
    case emptyDocument
    case invalidPageRange
    
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
        case .invalidPageRange:
            return "無効なページ範囲が指定されました"
        }
    }
}
