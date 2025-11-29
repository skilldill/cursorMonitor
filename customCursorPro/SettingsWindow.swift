import Cocoa
import SwiftUI

class SettingsWindow: NSWindowController {
    
    override init(window: NSWindow?) {
        super.init(window: window)
        createWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createWindow()
    }
    
    convenience init() {
        self.init(window: nil)
    }
    
    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 800),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L("settings.title")
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Предотвращаем сворачивание в боковую панель Stage Manager
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Устанавливаем минимальный размер окна
        window.minSize = NSSize(width: 500, height: 600)
        
        // Создаем SwiftUI view
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.view.frame = window.contentView!.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        
        window.contentView = hostingController.view
        
        // Устанавливаем делегат для обработки закрытия окна
        window.delegate = self
        
        self.window = window
    }
    
    func showWindow() {
        // Останавливаем основной курсор при открытии настроек
        NotificationCenter.default.post(name: .settingsWindowWillOpen, object: nil)
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension SettingsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Возобновляем основной курсор при закрытии настроек
        NotificationCenter.default.post(name: .settingsWindowWillClose, object: nil)
    }
}

extension Notification.Name {
    static let settingsWindowWillOpen = Notification.Name("settingsWindowWillOpen")
    static let settingsWindowWillClose = Notification.Name("settingsWindowWillClose")
}
