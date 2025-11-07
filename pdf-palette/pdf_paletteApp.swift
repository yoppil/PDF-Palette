//
//  pdf_paletteApp.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI

@main
struct pdf_paletteApp: App {
    var body: some Scene {
        WindowGroup {
            PDFPaletteView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
