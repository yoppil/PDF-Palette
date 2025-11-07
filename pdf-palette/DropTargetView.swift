//
//  DropTargetView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import Cocoa
import SwiftUI

/// ドラッグ&ドロップを受け付けるNSView
class DropTargetView: NSView {
    
    var onFilesDropped: (([URL]) -> Void)?
    
    // ドラッグ中のハイライト状態
    private var isHighlighted = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDragAndDrop()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragAndDrop()
    }
    
    // MARK: - ドラッグ&ドロップのセットアップ
    
    private func setupDragAndDrop() {
        // ファイルURLを受け付ける
        registerForDraggedTypes([.fileURL])
    }
    
    // MARK: - ドラッグ&ドロップのデリゲートメソッド
    
    /// ドラッグがビュー内に入った時
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // 内部ドラッグ（シェルフ内の並び替え）は無視
        if sender.draggingSource != nil {
            return []
        }
        // ペーストボードからファイルURLを取得
        let pasteboard = sender.draggingPasteboard
        
        // ファイルURLが含まれているか確認
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return []
        }
        
        // PDFファイルが含まれているか確認
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        
        if !pdfURLs.isEmpty {
            isHighlighted = true
            return .copy
        }
        
        return []
    }
    
    /// ドラッグがビュー内を移動している時
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingSource != nil {
            return []
        }
        return .copy
    }
    
    /// ドラッグがビューから出た時
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
    }
    
    /// ファイルがドロップされた時
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // 内部ドラッグは処理しない
        if sender.draggingSource != nil {
            return false
        }
        isHighlighted = false
        
        let pasteboard = sender.draggingPasteboard
        
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        
        // PDFファイルのみをフィルタリング
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        
        if !pdfURLs.isEmpty {
            // コールバックを呼び出し
            onFilesDropped?(pdfURLs)
            return true
        }
        
        return false
    }
    
    // MARK: - 描画
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // ハイライト時の表示
        if isHighlighted {
            // アンチエイリアシングを有効化
            NSGraphicsContext.current?.shouldAntialias = true
            NSGraphicsContext.current?.imageInterpolation = .high
            
            // 塗りつぶし
            NSColor.systemBlue.withAlphaComponent(0.1).setFill()
            let fillPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), xRadius: 16, yRadius: 16)
            fillPath.fill()
            
            // 枠線（滑らかな描画のため少し内側に）
            NSColor.systemBlue.withAlphaComponent(0.5).setStroke()
            let strokePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), xRadius: 16, yRadius: 16)
            strokePath.lineWidth = 3
            strokePath.lineCapStyle = .round
            strokePath.lineJoinStyle = .round
            strokePath.stroke()
        }
    }
}

// MARK: - SwiftUIラッパー

/// SwiftUIからDropTargetViewを使うためのラッパー
struct DropTargetViewRepresentable: NSViewRepresentable {
    
    let onFilesDropped: ([URL]) -> Void
    
    func makeNSView(context: Context) -> DropTargetView {
        let view = DropTargetView()
        view.onFilesDropped = onFilesDropped
        return view
    }
    
    func updateNSView(_ nsView: DropTargetView, context: Context) {
        nsView.onFilesDropped = onFilesDropped
    }
}
