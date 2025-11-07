import Foundation
import AppKit
import Combine
import SwiftUI

@MainActor
final class ShortcutManager: ObservableObject {
	static let shared = ShortcutManager()

	// MARK: Shortcut Types

	struct Shortcut: Codable, Equatable {
		enum Kind: String, Codable {
			case dualCommand
			case keyCombination
		}

		var kind: Kind
		var keyCode: UInt32
		var modifiers: ShortcutModifier

		// デフォルトは Option + ; (キーコード 41)
		static let dualCommand = Shortcut(kind: .keyCombination, keyCode: 41, modifiers: [.option])

		static func keyCombination(keyCode: UInt32, modifiers: ShortcutModifier) -> Shortcut {
			Shortcut(kind: .keyCombination, keyCode: keyCode, modifiers: modifiers)
		}

		var isDualCommand: Bool {
			kind == .dualCommand
		}

		var displayString: String {
			switch kind {
			case .dualCommand:
				return "⌥;"
			case .keyCombination:
				let modifierSymbols = modifiers.symbolString()
				let keyString = KeyCodeHelper.displayName(for: keyCode)
				return modifierSymbols.isEmpty ? keyString : modifierSymbols + keyString
			}
		}

		func matches(event: NSEvent) -> Bool {
			switch kind {
			case .dualCommand:
				return false
			case .keyCombination:
				return UInt32(event.keyCode) == keyCode && modifiers.matches(eventModifiers: event.modifierFlags)
			}
		}
	}

	struct ShortcutModifier: OptionSet, Codable {
		let rawValue: UInt32

		init(rawValue: UInt32) {
			self.rawValue = rawValue
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let rawValue = try container.decode(UInt32.self)
			self.init(rawValue: rawValue)
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(rawValue)
		}

		static let command = ShortcutModifier(rawValue: 1 << 0)
		static let option  = ShortcutModifier(rawValue: 1 << 1)
		static let control = ShortcutModifier(rawValue: 1 << 2)
		static let shift   = ShortcutModifier(rawValue: 1 << 3)

		init(modifierFlags: NSEvent.ModifierFlags) {
			let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
			var result: ShortcutModifier = []
			if flags.contains(.control) { result.insert(.control) }
			if flags.contains(.option) { result.insert(.option) }
			if flags.contains(.shift) { result.insert(.shift) }
			if flags.contains(.command) { result.insert(.command) }
			self = result
		}

		func symbolString() -> String {
			var symbols = ""
			if contains(.control) { symbols += "⌃" }
			if contains(.option) { symbols += "⌥" }
			if contains(.shift) { symbols += "⇧" }
			if contains(.command) { symbols += "⌘" }
			return symbols
		}

		static let allowed: ShortcutModifier = [.command, .option, .control, .shift]

		func normalized() -> ShortcutModifier {
			intersection(Self.allowed)
		}

		func matches(eventModifiers: NSEvent.ModifierFlags) -> Bool {
			let eventModifier = ShortcutModifier(modifierFlags: eventModifiers).normalized()
			return eventModifier == normalized()
		}
	}

	private let userDefaultsKey = "ShortcutManager.currentShortcut"

	@Published private(set) var currentShortcut: Shortcut = .dualCommand

	private var shortcutAction: (() -> Void)?
	private var globalFlagsMonitor: Any?
	private var localFlagsMonitor: Any?
	private var globalKeyDownMonitor: Any?
	private var localKeyDownMonitor: Any?
	private var leftCommandDown = false
	private var rightCommandDown = false
	private var dualCommandTriggered = false
	private var lastHandledEventTimestamp: TimeInterval?

	private init() {
		if let shortcut = loadShortcut() {
			currentShortcut = shortcut
		}
		checkAccessibilityPermissions()
	}

	func configure(action: @escaping () -> Void) {
		shortcutAction = action
		checkAccessibilityPermissions()
		registerShortcut(currentShortcut)
	}

	func updateShortcut(_ shortcut: Shortcut) {
		currentShortcut = shortcut
		saveShortcut(shortcut)
		registerShortcut(shortcut)
	}

	// MARK: Shortcut Registration

	private func registerShortcut(_ shortcut: Shortcut) {
		removeAllMonitors()
		dualCommandTriggered = false
		leftCommandDown = false
		rightCommandDown = false
		lastHandledEventTimestamp = nil

		// すべてのショートカットはkeyCombinationとして扱う
		guard !shortcut.modifiers.isEmpty else {
			NSLog("ShortcutManager: 修飾キーが含まれていないショートカットはサポートされません")
			return
		}
		setupKeyCombinationMonitor(for: shortcut)
	}

	private func setupDualCommandMonitor() {
		guard globalFlagsMonitor == nil && localFlagsMonitor == nil else { return }

		let handler: (NSEvent) -> NSEvent? = { [weak self] event in
			self?.handleCommandFlagsChange(event)
			return event
		}

		globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
			self?.handleCommandFlagsChange(event)
		}
		localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: handler)
	}

	private func removeDualCommandMonitor() {
		if let globalFlagsMonitor {
			NSEvent.removeMonitor(globalFlagsMonitor)
		}
		if let localFlagsMonitor {
			NSEvent.removeMonitor(localFlagsMonitor)
		}
		globalFlagsMonitor = nil
		localFlagsMonitor = nil
	}

	private func setupKeyCombinationMonitor(for shortcut: Shortcut) {
		globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
			self?.handleKeyDown(event, shortcut: shortcut)
		}

		localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
			guard let self else { return event }
			self.handleKeyDown(event, shortcut: shortcut)
			return event
		}
	}

	private func removeKeyCombinationMonitor() {
		if let globalKeyDownMonitor {
			NSEvent.removeMonitor(globalKeyDownMonitor)
		}
		if let localKeyDownMonitor {
			NSEvent.removeMonitor(localKeyDownMonitor)
		}
		globalKeyDownMonitor = nil
		localKeyDownMonitor = nil
		lastHandledEventTimestamp = nil
	}

	private func removeAllMonitors() {
		removeDualCommandMonitor()
		removeKeyCombinationMonitor()
	}

	private func handleCommandFlagsChange(_ event: NSEvent) {
	leftCommandDown = CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(55))
	rightCommandDown = CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(54))

		if leftCommandDown && rightCommandDown {
			if !dualCommandTriggered {
				dualCommandTriggered = true
				triggerShortcut()
			}
		} else {
			dualCommandTriggered = false
		}
	}

	private func handleKeyDown(_ event: NSEvent, shortcut: Shortcut) {
		guard shortcut.matches(event: event) else { return }
		guard shouldHandle(event: event) else { return }
		triggerShortcut()
	}

	private func shouldHandle(event: NSEvent) -> Bool {
		// リピートイベントは無視
		if event.isARepeat { return false }
		
		// 同じタイムスタンプのイベントは無視（重複防止）
		let timestamp = event.timestamp
		if let lastTimestamp = lastHandledEventTimestamp, abs(timestamp - lastTimestamp) < 0.1 {
			return false
		}
		lastHandledEventTimestamp = timestamp
		return true
	}

	private func triggerShortcut() {
		DispatchQueue.main.async { [weak self] in
			self?.shortcutAction?()
		}
	}

	// MARK: - Accessibility Permissions

	private func checkAccessibilityPermissions() {
		let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
		let accessEnabled = AXIsProcessTrustedWithOptions(options)
		
		if !accessEnabled {
			NSLog("⚠️ ShortcutManager: アクセシビリティ権限が必要です。システム環境設定で許可してください。")
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
				self?.showAccessibilityAlert()
			}
		} else {
			NSLog("✅ ShortcutManager: アクセシビリティ権限が有効です")
		}
	}

	private func showAccessibilityAlert() {
		let alert = NSAlert()
		alert.messageText = "アクセシビリティ権限が必要です"
		alert.informativeText = "グローバルショートカットキーを使用するには、システム環境設定でアクセシビリティ権限を許可してください。\n\n設定後、アプリを再起動してください。"
		alert.alertStyle = .warning
		alert.addButton(withTitle: "システム環境設定を開く")
		alert.addButton(withTitle: "後で")
		
		let response = alert.runModal()
		if response == .alertFirstButtonReturn {
			if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
				NSWorkspace.shared.open(url)
			}
		}
	}

	// MARK: Persistence

	private func loadShortcut() -> Shortcut? {
		guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
			return nil
		}
		return try? JSONDecoder().decode(Shortcut.self, from: data)
	}

	private func saveShortcut(_ shortcut: Shortcut) {
		if let data = try? JSONEncoder().encode(shortcut) {
			UserDefaults.standard.set(data, forKey: userDefaultsKey)
		}
	}
}

private enum KeyCodeHelper {
	static func displayName(for keyCode: UInt32) -> String {
		let code = UInt16(keyCode)
		if let name = keyMapping[code] {
			return name
		}
		if let functionName = functionKeyMapping[code] {
			return functionName
		}
		return "キーコード\(keyCode)"
	}

	private static let keyMapping: [UInt16: String] = [
		0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
		11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3",
		21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
		30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J",
		39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
		48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Escape",
		65: "Decimal", 67: "*", 69: "+", 71: "Clear", 75: "/", 76: "Enter", 78: "-", 81: "=",
		82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
		96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
		106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15", 114: "Help", 115: "Home",
		116: "PageUp", 117: "Delete", 118: "F4", 119: "End", 120: "F2", 121: "PageDown", 122: "F1",
		123: "←", 124: "→", 125: "↓", 126: "↑"
	]

	private static let functionKeyMapping: [UInt16: String] = [
		122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
		101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
		106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20"
	]
}

enum ShortcutCaptureError: LocalizedError {
	case needsModifier

	var errorDescription: String? {
		switch self {
		case .needsModifier:
			return "少なくとも1つの修飾キーを含めてください。"
		}
	}
}

enum ShortcutCaptureOutcome {
	case success(ShortcutManager.Shortcut)
	case failure(ShortcutCaptureError)
	case cancelled
}

struct ShortcutCaptureRepresentable: NSViewRepresentable {
	@Binding var isRecording: Bool
	var onFinished: (ShortcutCaptureOutcome) -> Void

	func makeNSView(context: Context) -> ShortcutCaptureView {
		let view = ShortcutCaptureView()
		view.onFinished = { outcome in
			DispatchQueue.main.async {
				onFinished(outcome)
			}
		}
		return view
	}

	func updateNSView(_ nsView: ShortcutCaptureView, context: Context) {
		if isRecording {
			nsView.beginRecording()
		} else {
			nsView.cancelRecording()
		}
	}
}

final class ShortcutCaptureView: NSView {
	var onFinished: ((ShortcutCaptureOutcome) -> Void)?
	private var recording = false

	override var acceptsFirstResponder: Bool { true }

	func beginRecording() {
		guard !recording else { return }
		recording = true
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			self.window?.makeFirstResponder(self)
		}
	}

	func cancelRecording() {
		guard recording else { return }
		recording = false
		if window?.firstResponder === self {
			window?.makeFirstResponder(nil)
		}
	}

	override func keyDown(with event: NSEvent) {
		guard recording else {
			super.keyDown(with: event)
			return
		}

		if event.keyCode == 53 { // Escape cancels recording
			cancelRecording()
			onFinished?(.cancelled)
			return
		}

		let modifiers = ShortcutManager.ShortcutModifier(modifierFlags: event.modifierFlags).normalized()

		guard !modifiers.isEmpty else {
			cancelRecording()
			onFinished?(.failure(.needsModifier))
			return
		}

		let shortcut = ShortcutManager.Shortcut.keyCombination(keyCode: UInt32(event.keyCode), modifiers: modifiers)
		cancelRecording()
		onFinished?(.success(shortcut))
	}

	override func flagsChanged(with event: NSEvent) {
		guard recording else { return }
		if event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
			cancelRecording()
			onFinished?(.cancelled)
		}
	}
}
