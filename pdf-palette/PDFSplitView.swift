//
//  PDFSplitView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import PDFKit
import UserNotifications
import Combine
import UniformTypeIdentifiers

/// PDF分割のためのページ選択ウィンドウ
struct PDFSplitView: View {
    let pdfURL: URL
    @StateObject private var viewModel: PDFSplitViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingOutputDialog = false
    @State private var isProcessing = false
    
    init(pdfURL: URL) {
        self.pdfURL = pdfURL
        _viewModel = StateObject(wrappedValue: PDFSplitViewModel(pdfURL: pdfURL))
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
                } else if viewModel.pages.isEmpty {
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
        .frame(width: 800, height: 600)
        .fileImporter(
            isPresented: $showingOutputDialog,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleOutputSelection(result: result)
        }
    }
    
    // MARK: - ヘッダー
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scissors")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PDF分割")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(pdfURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
            
            // ページ数と選択数
            HStack(spacing: 16) {
                Label("\(viewModel.pages.count) ページ", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if viewModel.selectedPageIndices.count > 0 {
                    Label("\(viewModel.selectedPageIndices.count) 選択中", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - メインコンテンツ
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // クイックアクション
            quickActionsView
            
            // ページグリッド
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        PageThumbnailView(
                            page: page,
                            pageNumber: index + 1,
                            isSelected: viewModel.selectedPageIndices.contains(index),
                            onTap: {
                                viewModel.togglePageSelection(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - クイックアクション
    
    private var quickActionsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.selectAll()
            }) {
                Label("すべて選択", systemImage: "checkmark.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: {
                viewModel.deselectAll()
            }) {
                Label("選択解除", systemImage: "circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Spacer()
            
            // 分割モード切り替え
            Picker("分割モード", selection: $viewModel.splitMode) {
                Label("選択ページのみ", systemImage: "doc.on.doc")
                    .tag(SplitMode.selectedPages)
                
                Label("すべてバラバラに", systemImage: "square.grid.2x2")
                    .tag(SplitMode.allSeparate)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - フッター
    
    private var footerView: some View {
        HStack {
            // 分割モード説明
            Text(viewModel.splitMode.description)
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
                Label("分割実行", systemImage: "scissors")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.splitMode == .selectedPages && viewModel.selectedPageIndices.isEmpty)
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
                
                Text("PDFを分割しています...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(viewModel.splitMode == .allSeparate ? viewModel.pages.count : viewModel.selectedPageIndices.count) ページ処理中")
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
    
    private func handleOutputSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let outputDirectory = urls.first else { return }
            
            // セキュリティスコープのアクセスを開始
            let hasAccess = outputDirectory.startAccessingSecurityScopedResource()
            
            if !hasAccess {
                print("❌ セキュリティスコープアクセスの取得に失敗")
            }
            
            isProcessing = true
            
            // 分割処理を実行
            viewModel.performSplit(outputDirectory: outputDirectory) { result in
                // 処理完了後にセキュリティスコープアクセスを解放
                outputDirectory.stopAccessingSecurityScopedResource()
                
                isProcessing = false
                
                switch result {
                case .success(let urls):
                    // 成功通知
                    showNotification(
                        title: "分割完了",
                        message: "\(urls.count)個のPDFファイルを作成しました"
                    )
                    
                    // Finderで表示
                    if !urls.isEmpty {
                        NSWorkspace.shared.activateFileViewerSelecting([urls[0]])
                    }
                    
                    // ウィンドウを閉じる
                    dismiss()
                    
                case .failure(let error):
                    // エラー通知
                    showNotification(
                        title: "分割エラー",
                        message: error.localizedDescription
                    )
                }
            }
            
        case .failure(let error):
            print("❌ フォルダ選択エラー: \(error.localizedDescription)")
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

// MARK: - ページサムネイルビュー

struct PageThumbnailView: View {
    let page: PDFPage
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // サムネイル
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.textBackgroundColor))
                    .frame(width: 100, height: 140)
                
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 130)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                // 選択インジケーター
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 20)
                                )
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : (isHovered ? Color.blue.opacity(0.5) : Color.clear), lineWidth: 3)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 8)
            
            // ページ番号
            Text("ページ \(pageNumber)")
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.blue.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let bounds = self.page.bounds(for: .mediaBox)
            let scale: CGFloat = 200 / max(bounds.width, bounds.height)
            let scaledSize = CGSize(
                width: bounds.width * scale,
                height: bounds.height * scale
            )
            
            let thumbnail = self.page.thumbnail(of: scaledSize, for: .mediaBox)
            
            DispatchQueue.main.async {
                self.thumbnail = thumbnail
            }
        }
    }
}

// MARK: - ViewModel

class PDFSplitViewModel: ObservableObject {
    @Published var pages: [PDFPage] = []
    @Published var selectedPageIndices: Set<Int> = []
    @Published var splitMode: SplitMode = .selectedPages
    @Published var isLoading = true
    
    private let pdfURL: URL
    private var pdfDocument: PDFDocument?
    
    init(pdfURL: URL) {
        self.pdfURL = pdfURL
        loadPDF()
    }
    
    private func loadPDF() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(url: self.pdfURL) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            self.pdfDocument = document
            var loadedPages: [PDFPage] = []
            
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    loadedPages.append(page)
                }
            }
            
            DispatchQueue.main.async {
                self.pages = loadedPages
                self.isLoading = false
            }
        }
    }
    
    func togglePageSelection(at index: Int) {
        if selectedPageIndices.contains(index) {
            selectedPageIndices.remove(index)
        } else {
            selectedPageIndices.insert(index)
        }
    }
    
    func selectAll() {
        selectedPageIndices = Set(0..<pages.count)
    }
    
    func deselectAll() {
        selectedPageIndices.removeAll()
    }
    
    func performSplit(outputDirectory: URL, completion: @escaping (Result<[URL], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let sourceDocument = self.pdfDocument else {
                    throw NSError(domain: "PDFSplitError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "PDFドキュメントが読み込まれていません"
                    ])
                }
                
                var outputURLs: [URL] = []
                let fileNamePrefix = self.pdfURL.deletingPathExtension().lastPathComponent
                
                switch self.splitMode {
                case .selectedPages:
                    // 選択されたページのみ分割
                    let sortedIndices = self.selectedPageIndices.sorted()
                    
                    for pageIndex in sortedIndices {
                        let outputURL = outputDirectory
                            .appendingPathComponent("\(fileNamePrefix)_page_\(pageIndex + 1).pdf")
                        
                        // 新しいPDFドキュメントを作成
                        let newDocument = PDFDocument()
                        
                        // 元のドキュメントからページを取得して挿入
                        if let page = sourceDocument.page(at: pageIndex) {
                            newDocument.insert(page, at: 0)
                            
                            // ファイルに書き込み
                            let writeSuccess = newDocument.write(to: outputURL)
                            
                            if writeSuccess {
                                outputURLs.append(outputURL)
                                print("✅ 保存成功: \(outputURL.lastPathComponent)")
                            } else {
                                print("❌ 保存失敗: \(outputURL.lastPathComponent)")
                                throw NSError(domain: "PDFSplitError", code: 2, userInfo: [
                                    NSLocalizedDescriptionKey: "ページ \(pageIndex + 1) の保存に失敗しました"
                                ])
                            }
                        }
                    }
                    
                case .allSeparate:
                    // すべてのページをバラバラに
                    for index in 0..<sourceDocument.pageCount {
                        let outputURL = outputDirectory
                            .appendingPathComponent("\(fileNamePrefix)_page_\(index + 1).pdf")
                        
                        // 新しいPDFドキュメントを作成
                        let newDocument = PDFDocument()
                        
                        // 元のドキュメントからページを取得して挿入
                        if let page = sourceDocument.page(at: index) {
                            newDocument.insert(page, at: 0)
                            
                            // ファイルに書き込み
                            let writeSuccess = newDocument.write(to: outputURL)
                            
                            if writeSuccess {
                                outputURLs.append(outputURL)
                                print("✅ 保存成功: \(outputURL.lastPathComponent)")
                            } else {
                                print("❌ 保存失敗: \(outputURL.lastPathComponent)")
                                throw NSError(domain: "PDFSplitError", code: 2, userInfo: [
                                    NSLocalizedDescriptionKey: "ページ \(index + 1) の保存に失敗しました"
                                ])
                            }
                        }
                    }
                }
                
                print("📊 合計 \(outputURLs.count) ファイルを保存しました")
                
                DispatchQueue.main.async {
                    completion(.success(outputURLs))
                }
                
            } catch {
                print("❌ 分割エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - 分割モード

enum SplitMode {
    case selectedPages
    case allSeparate
    
    var description: String {
        switch self {
        case .selectedPages:
            return "選択したページのみを個別のPDFとして保存します"
        case .allSeparate:
            return "すべてのページを個別のPDFとして保存します"
        }
    }
}

// MARK: - プレビュー

#Preview {
    PDFSplitView(pdfURL: URL(fileURLWithPath: "/path/to/sample.pdf"))
}
