//
//  PDFMergeView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import PDFKit
import UserNotifications
import Combine
import UniformTypeIdentifiers

/// PDF結合のためのプレビューと順序調整ウィンドウ
struct PDFMergeView: View {
    let pdfURLs: [URL]
    @StateObject private var viewModel: PDFMergeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingOutputDialog = false
    @State private var isProcessing = false
    
    init(pdfURLs: [URL]) {
        self.pdfURLs = pdfURLs
        _viewModel = StateObject(wrappedValue: PDFMergeViewModel(pdfURLs: pdfURLs))
    }
    
    var body: some View {
        ZStack {
            // Liquid Glass背景
            LiquidGlassView.window
            
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                Divider()
                    .padding(.horizontal, 20)
                
                // メインコンテンツ
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.pdfItems.isEmpty {
                    errorView
                } else {
                    contentView
                }
                
                Divider()
                    .padding(.horizontal, 20)
                
                // フッター（アクションボタン）
                footerView
            }
            .padding(20)
            
            // 処理中オーバーレイ
            if isProcessing {
                processingOverlay
            }
        }
        .frame(width: 900, height: 700)
        .fileExporter(
            isPresented: $showingOutputDialog,
            document: PDFExportDocument(),
            contentType: .pdf,
            defaultFilename: "Merged.pdf"
        ) { result in
            handleOutputSelection(result: result)
        }
    }
    
    // MARK: - ヘッダー
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PDF結合")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(viewModel.pdfItems.count)個のPDFファイル")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 閉じるボタン
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // 統計情報
            HStack(spacing: 16) {
                Label("\(viewModel.totalPages) ページ", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(viewModel.totalFileSize)", systemImage: "doc.badge.gearshape")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - メインコンテンツ
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // 説明テキスト
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("ファイルをドラッグして順序を変更できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // PDFアイテムリスト
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.pdfItems) { item in
                        PDFItemRow(
                            item: item,
                            onDelete: {
                                viewModel.removeItem(item)
                            },
                            onMoveUp: {
                                viewModel.moveItemUp(item)
                            },
                            onMoveDown: {
                                viewModel.moveItemDown(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - フッター
    
    private var footerView: some View {
        HStack {
            // 説明
            Text("結合後のファイルには\(viewModel.totalPages)ページが含まれます")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("キャンセル") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            
            Button(action: {
                showingOutputDialog = true
            }) {
                Label("結合実行", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.pdfItems.isEmpty)
        }
        .padding(.top, 12)
    }
    
    // MARK: - ローディング
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("PDFを読み込んでいます...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - エラー
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("PDFを読み込めませんでした")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 処理中オーバーレイ
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("PDFを結合しています...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(viewModel.totalPages) ページを処理中")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - 出力先選択処理
    
    private func handleOutputSelection(result: Result<URL, Error>) {
        switch result {
        case .success(let outputURL):
            isProcessing = true
            
            // 結合処理を実行
            viewModel.performMerge(outputURL: outputURL) { result in
                isProcessing = false
                
                switch result {
                case .success(let url):
                    // 成功通知
                    showNotification(
                        title: "結合完了",
                        message: "\(viewModel.totalPages)ページのPDFを作成しました"
                    )
                    
                    // Finderで表示
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    
                    // ウィンドウを閉じる
                    dismiss()
                    
                case .failure(let error):
                    // エラー通知
                    showNotification(
                        title: "結合エラー",
                        message: error.localizedDescription
                    )
                }
            }
            
        case .failure(let error):
            print("❌ ファイル選択エラー: \(error.localizedDescription)")
        }
    }
    
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
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - PDFアイテム行ビュー

struct PDFItemRow: View {
    let item: PDFItem
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    
    @State private var isHovered = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // メイン行
            HStack(spacing: 12) {
                // 順序番号
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text("\(item.order)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                // サムネイル（最初のページ）
                if let firstPage = item.firstPageThumbnail {
                    Image(nsImage: firstPage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 80)
                        .cornerRadius(4)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 60, height: 80)
                        .overlay(
                            Image(systemName: "doc.fill")
                                .foregroundColor(.red)
                        )
                }
                
                // ファイル情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.fileName)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(item.pageCount) ページ", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(item.fileSize, systemImage: "doc.badge.gearshape")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // プレビュー展開ボタン
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                // 操作ボタン
                if isHovered {
                    HStack(spacing: 8) {
                        // 上に移動
                        Button(action: onMoveUp) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("上に移動")
                        
                        // 下に移動
                        Button(action: onMoveDown) {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("下に移動")
                        
                        // 削除
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("削除")
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.blue.opacity(0.05) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(isHovered ? 0.3 : 0), lineWidth: 2)
            )
            
            // ページプレビュー展開部分
            if isExpanded {
                pagesPreviewView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - ページプレビュー
    
    private var pagesPreviewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.horizontal, 12)
            
            Text("ページプレビュー")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 8) {
                    ForEach(0..<item.pageThumbnails.count, id: \.self) { index in
                        VStack(spacing: 4) {
                            if let thumbnail = item.pageThumbnails[index] {
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 100)
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(width: 80, height: 100)
                            }
                            
                            Text("P.\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - ViewModel

class PDFMergeViewModel: ObservableObject {
    @Published var pdfItems: [PDFItem] = []
    @Published var isLoading = true
    
    private let pdfURLs: [URL]
    
    var totalPages: Int {
        pdfItems.reduce(0) { $0 + $1.pageCount }
    }
    
    var totalFileSize: String {
        let totalBytes = pdfItems.reduce(0) { $0 + $1.fileSizeBytes }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    init(pdfURLs: [URL]) {
        self.pdfURLs = pdfURLs
        loadPDFs()
    }
    
    private func loadPDFs() {
        DispatchQueue.global(qos: .userInitiated).async {
            var items: [PDFItem] = []
            
            for (index, url) in self.pdfURLs.enumerated() {
                guard let document = PDFDocument(url: url) else {
                    continue
                }
                
                // ファイルサイズ取得
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                
                // サムネイル生成
                var thumbnails: [NSImage?] = []
                for pageIndex in 0..<document.pageCount {
                    if let page = document.page(at: pageIndex) {
                        let thumbnail = self.generateThumbnail(for: page)
                        thumbnails.append(thumbnail)
                    } else {
                        thumbnails.append(nil)
                    }
                }
                
                let item = PDFItem(
                    id: UUID(),
                    url: url,
                    fileName: url.lastPathComponent,
                    pageCount: document.pageCount,
                    fileSizeBytes: fileSize,
                    order: index + 1,
                    document: document,
                    pageThumbnails: thumbnails
                )
                
                items.append(item)
            }
            
            DispatchQueue.main.async {
                self.pdfItems = items
                self.isLoading = false
            }
        }
    }
    
    private func generateThumbnail(for page: PDFPage) -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 160 / max(bounds.width, bounds.height)
        let scaledSize = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )
        
        return page.thumbnail(of: scaledSize, for: .mediaBox)
    }
    
    func removeItem(_ item: PDFItem) {
        pdfItems.removeAll { $0.id == item.id }
        updateOrder()
    }
    
    func moveItemUp(_ item: PDFItem) {
        guard let index = pdfItems.firstIndex(where: { $0.id == item.id }), index > 0 else {
            return
        }
        pdfItems.swapAt(index, index - 1)
        updateOrder()
    }
    
    func moveItemDown(_ item: PDFItem) {
        guard let index = pdfItems.firstIndex(where: { $0.id == item.id }), index < pdfItems.count - 1 else {
            return
        }
        pdfItems.swapAt(index, index + 1)
        updateOrder()
    }
    
    private func updateOrder() {
        for (index, _) in pdfItems.enumerated() {
            pdfItems[index].order = index + 1
        }
    }
    
    func performMerge(outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let mergedDocument = PDFDocument()
                var currentPageIndex = 0
                
                // 各PDFのページを順番に追加
                for item in self.pdfItems {
                    guard let document = item.document else {
                        continue
                    }
                    
                    for pageIndex in 0..<document.pageCount {
                        if let page = document.page(at: pageIndex) {
                            mergedDocument.insert(page, at: currentPageIndex)
                            currentPageIndex += 1
                            print("✅ ページ追加: \(item.fileName) - P.\(pageIndex + 1)")
                        }
                    }
                }
                
                // ファイルに書き込み
                let writeSuccess = mergedDocument.write(to: outputURL)
                
                if writeSuccess {
                    print("✅ 結合完了: \(outputURL.lastPathComponent) (\(currentPageIndex)ページ)")
                    DispatchQueue.main.async {
                        completion(.success(outputURL))
                    }
                } else {
                    throw NSError(domain: "PDFMergeError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "PDFファイルの保存に失敗しました"
                    ])
                }
                
            } catch {
                print("❌ 結合エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - PDFアイテムモデル

struct PDFItem: Identifiable {
    let id: UUID
    let url: URL
    let fileName: String
    let pageCount: Int
    let fileSizeBytes: Int64
    var order: Int
    let document: PDFDocument?
    let pageThumbnails: [NSImage?]
    
    var fileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
    
    var firstPageThumbnail: NSImage? {
        pageThumbnails.first ?? nil
    }
}

// MARK: - プレビュー

#Preview {
    PDFMergeView(pdfURLs: [
        URL(fileURLWithPath: "/path/to/sample1.pdf"),
        URL(fileURLWithPath: "/path/to/sample2.pdf")
    ])
}
