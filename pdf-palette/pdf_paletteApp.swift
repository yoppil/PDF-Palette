//
//  pdf_paletteApp.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import AppKit

@main
struct pdf_paletteApp: App {
    // AppDelegateを統合
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // メインウィンドウは非表示にする（メニューバーアプリとして動作）
        Settings {
            EmptyView()
        }
    }
}
