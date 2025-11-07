//
//  PDFExportDocument.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import UniformTypeIdentifiers

/// PDF結合用のエクスポートドキュメント
struct PDFExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    init() {}
    
    init(configuration: ReadConfiguration) throws {
        // 読み込みは不要
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // 実際の書き込みは別で行うので、空のファイルを返す
        return FileWrapper(regularFileWithContents: Data())
    }
}
