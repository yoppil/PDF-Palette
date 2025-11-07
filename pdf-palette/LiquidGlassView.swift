//
//  LiquidGlassView.swift
//  pdf-palette
//
//  Created by yoppii on 2025/11/07.
//

import SwiftUI
import AppKit

/// 本格的なLiquid Glass効果を提供するビュー
struct LiquidGlassView: NSViewRepresentable {
    
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        
        // Liquid Glass効果の設定
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        
        // 角丸の設定
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        
        // より美しいレンダリング
        view.layer?.cornerCurve = .continuous
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - プリセット

extension LiquidGlassView {
    /// フローティングパネル風のLiquid Glass（非常に透明）
    static var floatingPanel: LiquidGlassView {
        LiquidGlassView(
            material: .underWindowBackground,
            blendingMode: .behindWindow,
            state: .active
        )
    }
    
    /// より透明度の高いLiquid Glass
    static var ultraClear: LiquidGlassView {
        LiquidGlassView(
            material: .underWindowBackground,
            blendingMode: .behindWindow,
            state: .active
        )
    }
    
    /// 濃いめのLiquid Glass
    static var thick: LiquidGlassView {
        LiquidGlassView(
            material: .hudWindow,
            blendingMode: .behindWindow,
            state: .active
        )
    }
}
