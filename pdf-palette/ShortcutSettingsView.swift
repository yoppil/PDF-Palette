import SwiftUI

import SwiftUI

@MainActor
struct ShortcutSettingsView: View {
    @ObservedObject var manager: ShortcutManager
    @State private var isRecording = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ショートカットキー設定")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 4) {
                Text("現在のショートカット")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(manager.currentShortcut.displayString)
                    .font(.title3)
                    .monospaced()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button(action: startRecording) {
                    Text(isRecording ? "キー入力待機中..." : "ショートカットを変更")
                }
                .disabled(isRecording)

                Text("変更ボタンを押したあと、設定したいキーを同時に押してください。Escキーでキャンセルできます。")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                ShortcutCaptureRepresentable(isRecording: $isRecording) { outcome in
                    handleCaptureOutcome(outcome)
                }
                .frame(width: 0, height: 0)
            }

            Button("デフォルトに戻す (⌘⇧P)", action: restoreDualCommand)
                .padding(.top, 8)

            if let message = statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 380, height: 260)
    }

    private func startRecording() {
        statusMessage = nil
        isRecording = true
    }

    private func handleCaptureOutcome(_ outcome: ShortcutCaptureOutcome) {
        isRecording = false
        switch outcome {
        case .success(let shortcut):
            manager.updateShortcut(shortcut)
            statusMessage = "ショートカットを更新しました: \(manager.currentShortcut.displayString)"
        case .failure(let error):
            statusMessage = error.localizedDescription
        case .cancelled:
            statusMessage = "ショートカットの変更をキャンセルしました。"
        }
    }

    private func restoreDualCommand() {
        manager.updateShortcut(ShortcutManager.Shortcut.dualCommand)
        statusMessage = "デフォルトのショートカット (⌘⇧P) に戻しました。"
    }
}

#Preview {
    ShortcutSettingsView(manager: ShortcutManager.shared)
}
