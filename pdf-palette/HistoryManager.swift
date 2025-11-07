//
//  HistoryManager.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import Foundation
import Combine

/// Undo/Redo機能を管理するクラス
class HistoryManager: ObservableObject {
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    private var undoStack: [HistoryState] = []
    private var redoStack: [HistoryState] = []
    private let maxHistorySize: Int = 50
    
    /// 現在の状態を履歴に保存
    func saveState(_ state: HistoryState) {
        undoStack.append(state)
        redoStack.removeAll()
        
        // 履歴サイズの制限
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
        
        updateFlags()
    }
    
    /// Undo実行
    func undo() -> HistoryState? {
        guard !undoStack.isEmpty else { return nil }
        
        let state = undoStack.removeLast()
        redoStack.append(state)
        
        updateFlags()
        return state
    }
    
    /// Redo実行
    func redo() -> HistoryState? {
        guard !redoStack.isEmpty else { return nil }
        
        let state = redoStack.removeLast()
        undoStack.append(state)
        
        updateFlags()
        return state
    }
    
    /// 履歴をクリア
    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateFlags()
    }
    
    private func updateFlags() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}

/// 履歴に保存する状態（URLのみを保存）
struct HistoryState: Codable {
    let fileURLs: [URL]
    let selectedFileIds: Set<UUID>
    let focusedFileId: UUID?
    let timestamp: Date
    
    init(fileURLs: [URL], selectedFileIds: Set<UUID>, focusedFileId: UUID?) {
        self.fileURLs = fileURLs
        self.selectedFileIds = selectedFileIds
        self.focusedFileId = focusedFileId
        self.timestamp = Date()
    }
}
