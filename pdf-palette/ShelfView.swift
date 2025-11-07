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
    @State private var keyMonitor: Any?
    @State private var mouseUpMonitor: Any?
    @Namespace private var reorderNamespace
    
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
        .onAppear {
            if keyMonitor == nil {
                keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    return self.handleKeyEvent(event)
                }
            }
            if mouseUpMonitor == nil {
                mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { event in
                    viewModel.resetDragState(animated: true)
                    return event
                }
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
            if let mouseUpMonitor {
                NSEvent.removeMonitor(mouseUpMonitor)
                self.mouseUpMonitor = nil
            }
        }
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
    
    // MARK: - キーボードイベント処理
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags
        
        // Command + Shift キーの組み合わせ
        if modifiers.contains(.command) && modifiers.contains(.shift) {
            switch event.charactersIgnoringModifiers {
            case "z", "Z": // Command + Shift + Z: Redo
                viewModel.redo()
                return nil
            default:
                break
            }
        }
        
        // 矢印キー（Commandなし、Shiftあり/なし）
        if !modifiers.contains(.command) {
            let isShiftPressed = modifiers.contains(.shift)
            
            switch event.keyCode {
            case 126: // Up Arrow
                handleArrowKey(direction: .up, withShift: isShiftPressed)
                return nil
            case 125: // Down Arrow
                handleArrowKey(direction: .down, withShift: isShiftPressed)
                return nil
            case 123: // Left Arrow
                handleArrowKey(direction: .left, withShift: isShiftPressed)
                return nil
            case 124: // Right Arrow
                handleArrowKey(direction: .right, withShift: isShiftPressed)
                return nil
            case 49: // Space
                viewModel.toggleFocusedFileSelection()
                return nil
            case 51: // Delete/Backspace
                deleteSelectedFiles()
                return nil
            default:
                break
            }
            return event
        }
        
        // Command キーが押されている場合
        switch event.charactersIgnoringModifiers {
        case "z": // Command + Z: Undo
            viewModel.undo()
            return nil
            
        case "a": // Command + A: 全選択
            handleSelectAll()
            return nil
            
        case "c": // Command + C: コピー
            handleCopy()
            return nil
            
        case "x": // Command + X: 切り取り
            handleCut()
            return nil
            
        case "v": // Command + V: 貼り付け
            handlePaste()
            return nil
            
        default:
            break
        }
        
        // Command + Backspace
        if event.keyCode == 51 { // Delete/Backspace
            deleteSelectedFiles()
            return nil
        }
        
        return event
    }
    
    private func handleSelectAll() {
        viewModel.selectAll()
    }
    
    enum ArrowDirection {
        case up, down, left, right
    }
    
    private func handleArrowKey(direction: ArrowDirection, withShift: Bool) {
        // フォーカスを移動
        switch direction {
        case .up, .left:
            viewModel.moveFocusUp()
        case .down, .right:
            viewModel.moveFocusDown()
        }
        
        // Shiftキーが押されている場合は選択も更新
        if withShift {
            viewModel.toggleFocusedFileSelection()
        }
    }
    
    private func handleCopy() {
        let selectedFiles = viewModel.selectedFiles
        guard !selectedFiles.isEmpty else { return }
        
        // ペーストボードにファイルURLをコピー
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFiles.map { $0.url as NSURL }
        pasteboard.writeObjects(urls)
        
        print("📋 コピー: \(selectedFiles.count)個のファイル")
    }
    
    private func handleCut() {
        let selectedFiles = viewModel.selectedFiles
        guard !selectedFiles.isEmpty else { return }
        
        // ペーストボードにファイルURLをコピー
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFiles.map { $0.url as NSURL }
        pasteboard.writeObjects(urls)
        
        // ファイルを削除
        deleteSelectedFiles()
        
        print("✂️ 切り取り: \(selectedFiles.count)個のファイル")
    }
    
    private func deleteSelectedFiles() {
        let selectedIds = viewModel.selectedFileIds
        guard !selectedIds.isEmpty else { return }
        
        // 変更前の状態を保存
        viewModel.saveCurrentStatePublic()
        
        // 選択されているファイルを削除
        viewModel.pdfFiles.removeAll { selectedIds.contains($0.id) }
        viewModel.selectedFileIds.removeAll()
        viewModel.focusedFileId = nil
    }
    
    private func handlePaste() {
        let pasteboard = NSPasteboard.general
        
        // ペーストボードからファイルURLを取得
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return
        }
        
        // PDFファイルのみをフィルタリング
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        
        if !pdfURLs.isEmpty {
            viewModel.addFiles(pdfURLs)
            print("📥 貼り付け: \(pdfURLs.count)個のPDF")
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
                if !viewModel.selectedFileIds.isEmpty {
                    // 選択中のファイル情報
                    Text("\(viewModel.selectedFileIds.count) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                } else {
                    Text("\(viewModel.pdfFiles.count) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 分割ボタン（選択されたファイルが1つで複数ページの場合）
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
            
            // クリアボタン（選択されたファイルを削除）
            if !viewModel.selectedFileIds.isEmpty {
                Button(action: {
                    deleteSelectedFiles()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("選択したファイルを削除")
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
                    if viewModel.dropInsertionIndex == index {
                        insertionIndicator
                    }
                    FileItemView(file: file, index: index, viewModel: viewModel)
                        .matchedGeometryEffect(id: file.id, in: reorderNamespace)
                        .onDrag {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.draggedFileId = file.id
                                viewModel.dropTargetFileId = nil
                            }
                            return NSItemProvider(object: file.url as NSURL)
                        }
                        .onDrop(of: [.fileURL], delegate: FileDropDelegate(
                            file: file,
                            viewModel: viewModel,
                            index: index
                        ))
                }
                if viewModel.dropInsertionIndex == viewModel.pdfFiles.count {
                    insertionIndicator
                }
            }
            .padding(.vertical, 8)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.25),
                value: viewModel.pdfFiles.map { $0.id }
            )
        }
        .frame(maxHeight: .infinity)
    }

    private var insertionIndicator: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 3, height: 120)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.15), value: viewModel.dropInsertionIndex)
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
    static let tileWidth: CGFloat = 110
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        viewModel.selectedFileIds.contains(file.id)
    }
    
    private var isFocused: Bool {
        viewModel.focusedFileId == file.id
    }

    private var isDropTarget: Bool {
        viewModel.dropTargetFileId == file.id && viewModel.draggedFileId != nil
    }

    private var isBeingDragged: Bool {
        viewModel.draggedFileId == file.id
    }

    private var isRecentlyMoved: Bool {
        viewModel.lastMovedFileId == file.id
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
                    .stroke(
                        isSelected ? Color.blue : (isDropTarget ? Color.accentColor.opacity(0.6) : (isFocused ? Color.blue.opacity(0.4) : Color.clear)),
                        lineWidth: isSelected ? 3 : (isDropTarget ? 3 : 2)
                    )
            )
            .overlay(
                Group {
                    if isBeingDragged {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                    }
                }
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
        .cornerRadius(8)
        .opacity(isBeingDragged ? 0.05 : 1)
        .scaleEffect(isRecentlyMoved ? 1.06 : 1)
        .shadow(color: isRecentlyMoved ? Color.accentColor.opacity(0.35) : Color.clear, radius: isRecentlyMoved ? 8 : 0, x: 0, y: 5)
        .animation(.easeInOut(duration: 0.2), value: viewModel.draggedFileId)
        .animation(.easeInOut(duration: 0.2), value: viewModel.dropTargetFileId)
        .animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.25), value: viewModel.lastMovedFileId)
        .frame(width: Self.tileWidth)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            let isCommandPressed = NSEvent.modifierFlags.contains(.command)
            viewModel.selectFile(file, isCommandPressed: isCommandPressed)
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
        // このビューがイベントを受け取り、ウィンドウをドラッグ可能にする
        return self
    }
    
    override func mouseDown(with event: NSEvent) {
        // ウィンドウをドラッグ開始
        window?.performDrag(with: event)
    }
}

// MARK: - ファイルドロップデリゲート

struct FileDropDelegate: DropDelegate {
    let file: PDFFileItem
    let viewModel: ShelfViewModel
    let index: Int
    private static let decisionWidth: CGFloat = FileItemView.tileWidth
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedFileId = viewModel.draggedFileId else {
            return false
        }
        let insertionIndex = viewModel.dropInsertionIndex ?? index
        viewModel.moveFile(draggedFileId, toInsertionIndex: insertionIndex)
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedFileId = viewModel.draggedFileId,
              draggedFileId != file.id else {
            return
        }
        updateInsertionIndex(with: info)
        withAnimation(.easeInOut(duration: 0.15)) {
            viewModel.dropTargetFileId = file.id
        }
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return viewModel.draggedFileId != nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard let draggedFileId = viewModel.draggedFileId,
              draggedFileId != file.id else {
            return DropProposal(operation: .cancel)
        }
        updateInsertionIndex(with: info)
        withAnimation(.easeInOut(duration: 0.15)) {
            viewModel.dropTargetFileId = file.id
        }
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        if viewModel.dropTargetFileId == file.id {
            withAnimation(.easeOut(duration: 0.15)) {
                viewModel.dropTargetFileId = nil
            }
        }
        if viewModel.dropInsertionIndex == index || viewModel.dropInsertionIndex == index + 1 {
            viewModel.updateDropInsertionIndex(nil)
        }
    }

    func dropEnded(info: DropInfo) {
        viewModel.resetDragState(animated: true)
    }

    private func updateInsertionIndex(with info: DropInfo) {
        guard viewModel.draggedFileId != nil else { return }
        let location = info.location
        let threshold = Self.decisionWidth / 2
        let insertAfter = location.x > threshold
        let proposedIndex = insertAfter ? index + 1 : index
        let clamped = max(0, min(proposedIndex, viewModel.pdfFiles.count))
        viewModel.updateDropInsertionIndex(clamped)
    }
}

// MARK: - プレビュー

#Preview {
    ShelfView(viewModel: ShelfViewModel())
        .frame(width: 600, height: 200)
}
