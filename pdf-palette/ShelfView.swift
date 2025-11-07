//
//  ShelfView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// Dropover風のフローティングシェルフUI
struct ShelfView: View {
    @ObservedObject var viewModel: ShelfViewModel
    @State private var showingMergeWindow = false
    @State private var showingSplitWindow = false
    
    var body: some View {
        ZStack {
            // Liquid Glass背景
            LiquidGlassView.floatingPanel
            
            // ドロップターゲット
            DropTargetViewRepresentable { urls in
                viewModel.addFiles(urls)
            }
            
            VStack(spacing: 0) {
                // ヘッダー（ドラッグ可能エリア）
                headerView
                    .background(DraggableAreaView())
                
                Divider()
                    .padding(.horizontal, 12)
                
                // ファイル一覧
                if viewModel.pdfFiles.isEmpty {
                    emptyStateView
                } else {
                    fileListView
                }
                
                // 処理中インジケーター
                if viewModel.isProcessing {
                    processingView
                }
            }
            .padding(12)
            .allowsHitTesting(viewModel.pdfFiles.isEmpty ? false : true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: showingMergeWindow) { _, isShowing in
            if isShowing {
                let urls = viewModel.pdfFiles.map { $0.url }
                openMergeWindow(for: urls)
            }
        }
        .onChange(of: showingSplitWindow) { _, isShowing in
            if isShowing, let selectedFile = viewModel.selectedFile {
                openSplitWindow(for: selectedFile.url)
            }
        }
    }
    
    // MARK: - 結合ウィンドウを開く
    
    private func openMergeWindow(for urls: [URL]) {
        let mergeView = PDFMergeView(pdfURLs: urls)
        let hostingController = NSHostingController(rootView: mergeView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "PDF結合"
        window.styleMask = [NSWindow.StyleMask.titled, .closable, .resizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setContentSize(NSSize(width: 900, height: 700))
        
        // Liquid Glass効果
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        
        window.makeKeyAndOrderFront(nil as Any?)
        
        // ウィンドウが閉じられたらフラグをリセット
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [self] _ in
            showingMergeWindow = false
        }
    }
    
    // MARK: - 分割ウィンドウを開く
    
    private func openSplitWindow(for url: URL) {
        let splitView = PDFSplitView(pdfURL: url)
        let hostingController = NSHostingController(rootView: splitView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "PDF分割"
        window.styleMask = [NSWindow.StyleMask.titled, .closable, .resizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setContentSize(NSSize(width: 800, height: 600))
        
        // Liquid Glass効果
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        
        window.makeKeyAndOrderFront(nil as Any?)
        
        // ウィンドウが閉じられたらフラグをリセット
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [self] _ in
            showingSplitWindow = false
        }
    }
    
    // MARK: - ヘッダー
    
    private var headerView: some View {
        HStack {
            Image(systemName: "tray.fill")
                .font(.system(size: 18))
                .foregroundColor(.blue)
            
            Spacer()
            
            // ファイル数表示
            if !viewModel.pdfFiles.isEmpty {
                if let selectedFile = viewModel.selectedFile {
                    // 選択中のファイル情報
                    Text("\(selectedFile.fileName) (\(selectedFile.pageCount)p)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                } else {
                    Text("\(viewModel.pdfFiles.count) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 分割ボタン（選択されたファイルが複数ページの場合）
            if let selectedFile = viewModel.selectedFile, selectedFile.isMultiPage {
                Button(action: {
                    showingSplitWindow = true
                }) {
                    Label("Split", systemImage: "scissors")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
                .help("選択したPDFを分割")
            }
            
            // 結合ボタン（ファイルが2つ以上の場合）
            if viewModel.pdfFiles.count > 1 {
                Button(action: {
                    showingMergeWindow = true
                }) {
                    Label("Merge", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("すべてのPDFを1つに結合")
            }
            
            // クリアボタン
            if !viewModel.pdfFiles.isEmpty {
                Button(action: {
                    viewModel.clearAll()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("すべてクリア")
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - 空の状態
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .opacity(0.5)
            
            Text("Drop PDF files here")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - ファイル一覧
    
    private var fileListView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 12) {
                ForEach(Array(viewModel.pdfFiles.enumerated()), id: \.element.id) { index, file in
                    FileItemView(file: file, index: index, viewModel: viewModel)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 処理中表示
    
    private var processingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(viewModel.processingMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - ファイルアイテムビュー

struct FileItemView: View {
    let file: PDFFileItem
    let index: Int
    @ObservedObject var viewModel: ShelfViewModel
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        viewModel.selectedFileId == file.id
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // PDFサムネイルまたはアイコン
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: 80, height: 100)
                
                if let thumbnail = file.thumbnail {
                    // サムネイルがある場合は表示
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 75, height: 95)
                        .cornerRadius(6)
                } else {
                    // ローディング中はプレースホルダー
                    VStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : (isHovered ? Color.blue.opacity(0.5) : Color.clear), lineWidth: isSelected ? 3 : 2)
            )
            
            // ファイル名
            Text(file.fileName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            // ページ数とファイルサイズ
            VStack(spacing: 2) {
                if file.pageCount > 0 {
                    Text("\(file.pageCount) ページ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(file.fileSize)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.blue.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            viewModel.selectFile(file)
        }
        .contextMenu {
            Button("削除") {
                viewModel.removeFile(at: index)
            }
            
            Button("Finderで表示") {
                NSWorkspace.shared.activateFileViewerSelecting([file.url])
            }
        }
    }
}

// MARK: - ドラッグ可能エリア

struct DraggableAreaView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableNSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // 更新不要
    }
}

class DraggableNSView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // このビューがイベントを受け取るが、子ビューのインタラクションも許可
        return nil
    }
}

// MARK: - プレビュー

#Preview {
    ShelfView(viewModel: ShelfViewModel())
        .frame(width: 600, height: 200)
}
