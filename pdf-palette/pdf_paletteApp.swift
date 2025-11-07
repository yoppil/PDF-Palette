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
        DocumentGroup(newDocument: pdf_paletteDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
