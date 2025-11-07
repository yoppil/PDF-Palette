//
//  AppDelegate.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import Cocoa
import SwiftUI
import Combine
import UserNotifications
import PDFKit

/// アプリケーションのライフサイクルとメニューバーを管理するデリゲート
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // メニューバーのステータスアイテム
    var statusItem: NSStatusItem?
    
    // フローティングシェルフウィンドウ
    var shelfWindow: NSWindow?
    
    // シェルフの状態管理
    var shelfViewModel = ShelfViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 通知の許可をリクエスト
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知許可エラー: \(error.localizedDescription)")
            }
        }
        
        // メニューバーアイテムを作成
        setupMenuBarItem()
        
        // フローティングウィンドウを作成（最初は非表示）
        setupShelfWindow()
    }
    
    // MARK: - メニューバーアイテムのセットアップ
    
    private func setupMenuBarItem() {
        // ステータスバーにアイテムを追加
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // SF Symbolsのアイコンを使用
            button.image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "PDF Palette")
            button.action = #selector(toggleShelf)
            button.target = self
        }
        
        // 右クリックメニューも追加
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "シェルフを表示/非表示", action: #selector(toggleShelf), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    // MARK: - フローティングウィンドウのセットアップ
    
    private func setupShelfWindow() {
        // ウィンドウのサイズと位置
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 200
        
        // 画面の右下に配置
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let xPosition = screenFrame.maxX - windowWidth - 20
        let yPosition = screenFrame.minY + 20
        
        let contentRect = NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        
        // ボーダーレスで常に最前面のウィンドウを作成
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // ウィンドウの設定（Liquid Glass用）
        window.level = .floating  // 常に最前面
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = false  // ヘッダー部分のみドラッグ可能にする
        window.alphaValue = 0.95  // 全体の透明度を少し上げる
        
        // より美しい影
        window.invalidateShadow()
        
        // 描画品質の向上
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 16
        window.contentView?.layer?.masksToBounds = false  // 影を表示するためfalse
        window.contentView?.layer?.cornerCurve = .continuous  // より滑らかな角丸
        
        // 美しい影の設定
        window.contentView?.layer?.shadowColor = NSColor.black.cgColor
        window.contentView?.layer?.shadowOpacity = 0.3
        window.contentView?.layer?.shadowOffset = CGSize(width: 0, height: -10)
        window.contentView?.layer?.shadowRadius = 20
        
        // より強いVibrancy効果を適用
        if #available(macOS 10.14, *) {
            window.titlebarAppearsTransparent = true
        }
        
        // SwiftUIビューをコンテンツとして設定
        let shelfView = ShelfView(viewModel: shelfViewModel)
        let hostingView = NSHostingView(rootView: shelfView)
        hostingView.wantsLayer = true
        window.contentView = hostingView
        
        self.shelfWindow = window
    }
    
    // MARK: - アクション
    
    @objc private func toggleShelf() {
        guard let window = shelfWindow else { return }
        
        if window.isVisible {
            // フェードアウトアニメーション
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.orderOut(nil)
                window.alphaValue = 1.0
            })
        } else {
            // フェードインアニメーション
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                window.animator().alphaValue = 1.0
            })
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - シェルフのViewModel

/// シェルフに表示するファイルの状態を管理
class ShelfViewModel: ObservableObject {
    @Published var pdfFiles: [PDFFileItem] = []
    @Published var isProcessing: Bool = false
    @Published var processingMessage: String = ""
    @Published var selectedFileIndices: Set<Int> = []
    @Published var selectedFileIds: Set<UUID> = []  // 複数選択用
    @Published var focusedFileId: UUID? = nil  // カーソル位置
    @Published var draggedFileId: UUID? = nil  // ドラッグ中のファイル
    @Published var dropTargetFileId: UUID? = nil  // ドロップ先ハイライト
    
    let historyManager = HistoryManager()
    
    /// ファイルを移動
    func moveFile(from sourceId: UUID, to targetId: UUID) {
        guard let sourceIndex = pdfFiles.firstIndex(where: { $0.id == sourceId }),
              let targetIndex = pdfFiles.firstIndex(where: { $0.id == targetId }),
              sourceIndex != targetIndex else {
            return
        }
        
        // 変更前の状態を保存
        saveCurrentState()
        
        // ファイルを移動
        let movedFile = pdfFiles.remove(at: sourceIndex)
        pdfFiles.insert(movedFile, at: targetIndex)
    }
    
    /// 現在の状態を履歴に保存
    private func saveCurrentState() {
        let state = HistoryState(
            fileURLs: pdfFiles.map { $0.url },
            selectedFileIds: selectedFileIds,
            focusedFileId: focusedFileId
        )
        historyManager.saveState(state)
    }
    
    /// 外部から呼び出せる履歴保存メソッド
    func saveCurrentStatePublic() {
        saveCurrentState()
    }
    
    /// Undo実行
    func undo() {
        guard let state = historyManager.undo() else { return }
        restoreState(state)
    }
    
    /// Redo実行
    func redo() {
        guard let state = historyManager.redo() else { return }
        restoreState(state)
    }
    
    /// 状態を復元
    private func restoreState(_ state: HistoryState) {
        // URLからPDFFileItemを再生成
        let restoredFiles = state.fileURLs.map { url -> PDFFileItem in
            var item = PDFFileItem(url: url)
            
            // ページ数とサムネイルを取得
            if let pdfDocument = PDFDocument(url: url) {
                item.pageCount = pdfDocument.pageCount
                if let firstPage = pdfDocument.page(at: 0) {
                    let bounds = firstPage.bounds(for: .mediaBox)
                    let scale: CGFloat = 160 / max(bounds.width, bounds.height)
                    let scaledSize = CGSize(
                        width: bounds.width * scale,
                        height: bounds.height * scale
                    )
                    item.thumbnail = firstPage.thumbnail(of: scaledSize, for: .mediaBox)
                }
            }
            
            return item
        }
        
        pdfFiles = restoredFiles
        selectedFileIds = state.selectedFileIds
        focusedFileId = state.focusedFileId
    }
    
    /// 選択されたファイル（単一）
    var selectedFile: PDFFileItem? {
        guard let id = selectedFileIds.first, selectedFileIds.count == 1 else { return nil }
        return pdfFiles.first { $0.id == id }
    }
    
    /// 選択されたファイルのインデックス（単一）
    var selectedFileIndex: Int? {
        guard let file = selectedFile else { return nil }
        return pdfFiles.firstIndex { $0.id == file.id }
    }
    
    /// 選択されたファイルのリスト
    var selectedFiles: [PDFFileItem] {
        return pdfFiles.filter { selectedFileIds.contains($0.id) }
    }
    
    /// フォーカスされたファイル
    var focusedFile: PDFFileItem? {
        guard let id = focusedFileId else { return nil }
        return pdfFiles.first { $0.id == id }
    }
    
    /// フォーカスされたファイルのインデックス
    var focusedFileIndex: Int? {
        guard let id = focusedFileId else { return nil }
        return pdfFiles.firstIndex { $0.id == id }
    }
    
    /// ファイルを選択（Command+クリック対応）
    func selectFile(_ file: PDFFileItem, isCommandPressed: Bool) {
        if isCommandPressed {
            // Command+クリック: 複数選択トグル
            if selectedFileIds.contains(file.id) {
                selectedFileIds.remove(file.id)
                // 選択が空になったらフォーカスもクリア
                if selectedFileIds.isEmpty {
                    focusedFileId = nil
                }
            } else {
                selectedFileIds.insert(file.id)
                focusedFileId = file.id
            }
        } else {
            // 通常クリック: 単一選択
            if selectedFileIds.contains(file.id) && selectedFileIds.count == 1 {
                // 既に選択されている場合は解除
                selectedFileIds.removeAll()
                focusedFileId = nil
            } else {
                selectedFileIds = [file.id]
                focusedFileId = file.id
            }
        }
    }
    
    /// 全選択
    func selectAll() {
        selectedFileIds = Set(pdfFiles.map { $0.id })
        if let lastFile = pdfFiles.last {
            focusedFileId = lastFile.id
        }
    }
    
    /// カーソルを上に移動
    func moveFocusUp() {
        guard let currentIndex = focusedFileIndex, currentIndex > 0 else {
            // フォーカスがない場合は最後のファイルにフォーカス
            if !pdfFiles.isEmpty {
                focusedFileId = pdfFiles.last?.id
            }
            return
        }
        focusedFileId = pdfFiles[currentIndex - 1].id
    }
    
    /// カーソルを下に移動
    func moveFocusDown() {
        guard let currentIndex = focusedFileIndex, currentIndex < pdfFiles.count - 1 else {
            // フォーカスがない場合は最初のファイルにフォーカス
            if !pdfFiles.isEmpty {
                focusedFileId = pdfFiles.first?.id
            }
            return
        }
        focusedFileId = pdfFiles[currentIndex + 1].id
    }
    
    /// Spaceキーでフォーカスされたファイルを選択/解除
    func toggleFocusedFileSelection() {
        guard let id = focusedFileId else { return }
        if selectedFileIds.contains(id) {
            selectedFileIds.remove(id)
        } else {
            selectedFileIds.insert(id)
        }
    }
    
    /// ファイルをシェルフに追加
    func addFiles(_ urls: [URL]) {
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        
        // バックグラウンドでサムネイルとページ数を取得
        DispatchQueue.global(qos: .userInitiated).async {
            var newItems: [PDFFileItem] = []
            
            for url in pdfURLs {
                var item = PDFFileItem(url: url)
                
                // PDFドキュメントを読み込み
                if let document = PDFDocument(url: url) {
                    // ページ数を取得
                    item.pageCount = document.pageCount
                    
                    // 最初のページのサムネイルを生成
                    if let firstPage = document.page(at: 0) {
                        let bounds = firstPage.bounds(for: .mediaBox)
                        let scale: CGFloat = 160 / max(bounds.width, bounds.height)
                        let scaledSize = CGSize(
                            width: bounds.width * scale,
                            height: bounds.height * scale
                        )
                        item.thumbnail = firstPage.thumbnail(of: scaledSize, for: .mediaBox)
                    }
                }
                
                newItems.append(item)
            }
            
            DispatchQueue.main.async {
                // 変更前の状態を保存
                self.saveCurrentState()
                self.pdfFiles.append(contentsOf: newItems)
            }
        }
    }
    
    /// ファイルをシェルフから削除
    func removeFile(at index: Int) {
        guard index < pdfFiles.count else { return }
        
        // 変更前の状態を保存
        saveCurrentState()
        
        let fileId = pdfFiles[index].id
        
        // 削除するファイルが選択中の場合は選択を解除
        selectedFileIds.remove(fileId)
        if focusedFileId == fileId {
            focusedFileId = nil
        }
        
        pdfFiles.remove(at: index)
    }
    
    /// 全ファイルをクリア
    func clearAll() {
        // 変更前の状態を保存
        saveCurrentState()
        
        pdfFiles.removeAll()
        selectedFileIndices.removeAll()
        selectedFileIds.removeAll()
        focusedFileId = nil
    }
    
    // MARK: - PDF操作
    
    /// 複数のPDFを結合
    func mergePDFs(outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard !pdfFiles.isEmpty else {
            completion(.failure(PDFError.noInputFiles))
            return
        }
        
        isProcessing = true
        processingMessage = "PDFを結合しています..."
        
        // バックグラウンドで処理
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let inputURLs = self.pdfFiles.map { $0.url }
                _ = try PDFManager.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processingMessage = ""
                    completion(.success(outputURL))
                    self.showNotification(title: "結合完了", message: "\(self.pdfFiles.count)個のPDFを結合しました")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processingMessage = ""
                    completion(.failure(error))
                    self.showNotification(title: "エラー", message: "結合に失敗しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// PDFを分割（1ページずつ）
    func splitPDF(fileIndex: Int, outputDirectory: URL, completion: @escaping (Result<[URL], Error>) -> Void) {
        guard fileIndex < pdfFiles.count else {
            completion(.failure(PDFError.noInputFiles))
            return
        }
        
        isProcessing = true
        processingMessage = "PDFを分割しています..."
        
        let inputURL = pdfFiles[fileIndex].url
        
        // バックグラウンドで処理
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let outputURLs = try PDFManager.splitPDF(
                    inputURL: inputURL,
                    outputDirectory: outputDirectory,
                    fileNamePrefix: inputURL.deletingPathExtension().lastPathComponent
                )
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processingMessage = ""
                    completion(.success(outputURLs))
                    self.showNotification(title: "分割完了", message: "\(outputURLs.count)ページに分割しました")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processingMessage = ""
                    completion(.failure(error))
                    self.showNotification(title: "エラー", message: "分割に失敗しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 通知を表示
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知エラー: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - PDFファイルアイテムモデル

/// シェルフに表示するPDFファイルの情報
struct PDFFileItem: Identifiable {
    let id = UUID()
    let url: URL
    var isSelected: Bool = false
    var thumbnail: NSImage? = nil
    var pageCount: Int = 0
    
    var fileName: String {
        url.lastPathComponent
    }
    
    var fileSize: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var isMultiPage: Bool {
        return pageCount > 1
    }
}
