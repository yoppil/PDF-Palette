//
//  ContentView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: pdf_paletteDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(pdf_paletteDocument()))
}
