//
//  PDFPaletteView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFPaletteView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MergeView()
                .tabItem {
                    Label("結合", systemImage: "doc.on.doc")
                }
                .tag(0)
            
            SplitView()
                .tabItem {
                    Label("分割", systemImage: "scissors")
                }
                .tag(1)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// MARK: - 結合View

struct MergeView: View {
    @State private var selectedFiles: [URL] = []
    @State private var isProcessing = false
    @State private var resultMessage = ""
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PDF結合")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("複数のPDFファイルを1つに結合します")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // ファイルリスト
            if selectedFiles.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("PDFファイルを選択してください")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("選択されたファイル: \(selectedFiles.count)個")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, file in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.red)
                                    Text("\(index + 1). \(file.lastPathComponent)")
                                    Spacer()
                                    Button(action: {
                                        selectedFiles.remove(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
            }
            
            Spacer()
            
            // ボタン
            HStack(spacing: 20) {
                Button(action: selectFiles) {
                    Label("ファイルを選択", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                if !selectedFiles.isEmpty {
                    Button(action: {
                        selectedFiles.removeAll()
                    }) {
                        Label("クリア", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            
            Button(action: mergePDFs) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Label("結合を実行", systemImage: "arrow.right.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedFiles.count < 2 || isProcessing)
            .frame(maxWidth: .infinity)
        }
        .padding(30)
        .alert("結合結果", isPresented: $showResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.pdf]
        panel.message = "結合するPDFファイルを選択してください"
        
        if panel.runModal() == .OK {
            selectedFiles.append(contentsOf: panel.urls)
        }
    }
    
    private func mergePDFs() {
        isProcessing = true
        resultMessage = ""
        
        // 出力先を選択
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "Merged.pdf"
        savePanel.message = "結合されたPDFの保存先を選択してください"
        
        if savePanel.runModal() == .OK, let outputURL = savePanel.url {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let success = try PDFManager.mergePDFs(inputURLs: selectedFiles, outputURL: outputURL)
                    
                    DispatchQueue.main.async {
                        isProcessing = false
                        if success {
                            if let pageCount = PDFManager.getPageCount(url: outputURL) {
                                resultMessage = "✅ PDFの結合に成功しました！\n\nファイル: \(outputURL.lastPathComponent)\nページ数: \(pageCount)"
                            } else {
                                resultMessage = "✅ PDFの結合に成功しました！\n\nファイル: \(outputURL.lastPathComponent)"
                            }
                            selectedFiles.removeAll()
                        }
                        showResult = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        isProcessing = false
                        resultMessage = "❌ エラー: \(error.localizedDescription)"
                        showResult = true
                    }
                }
            }
        } else {
            isProcessing = false
        }
    }
}

// MARK: - 分割View

struct SplitView: View {
    @State private var selectedFile: URL?
    @State private var isProcessing = false
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var pageCount: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PDF分割")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("PDFファイルを1ページずつ分割します")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // ファイル選択
            if let file = selectedFile {
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(file.lastPathComponent)
                                .font(.headline)
                            
                            if let count = pageCount {
                                Text("\(count) ページ")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedFile = nil
                            pageCount = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "scissors")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("PDFファイルを選択してください")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                )
            }
            
            Spacer()
            
            // ボタン
            Button(action: selectFile) {
                Label("ファイルを選択", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            Button(action: splitPDF) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Label("分割を実行", systemImage: "arrow.right.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedFile == nil || isProcessing)
            .frame(maxWidth: .infinity)
        }
        .padding(30)
        .alert("分割結果", isPresented: $showResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.pdf]
        panel.message = "分割するPDFファイルを選択してください"
        
        if panel.runModal() == .OK, let url = panel.urls.first {
            selectedFile = url
            pageCount = PDFManager.getPageCount(url: url)
        }
    }
    
    private func splitPDF() {
        guard let inputURL = selectedFile else { return }
        
        isProcessing = true
        resultMessage = ""
        
        // 出力先ディレクトリを選択
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.message = "分割されたPDFファイルの保存先フォルダを選択してください"
        
        if panel.runModal() == .OK, let outputDirectory = panel.urls.first {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let outputURLs = try PDFManager.splitPDF(
                        inputURL: inputURL,
                        outputDirectory: outputDirectory,
                        fileNamePrefix: "Page"
                    )
                    
                    DispatchQueue.main.async {
                        isProcessing = false
                        resultMessage = "✅ PDFの分割に成功しました！\n\n\(outputURLs.count)個のファイルを作成しました\n保存先: \(outputDirectory.path)"
                        showResult = true
                        selectedFile = nil
                        pageCount = nil
                    }
                } catch {
                    DispatchQueue.main.async {
                        isProcessing = false
                        resultMessage = "❌ エラー: \(error.localizedDescription)"
                        showResult = true
                    }
                }
            }
        } else {
            isProcessing = false
        }
    }
}

// MARK: - Preview

#Preview {
    PDFPaletteView()
}
