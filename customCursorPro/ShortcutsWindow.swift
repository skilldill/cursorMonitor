import SwiftUI
import Cocoa

struct ShortcutsView: View {
    var onClose: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .padding(.bottom, 8)
            
            Divider()
            
            // Список шорткатов со скроллом
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ShortcutRow(
                        title: "Open Menu",
                        description: "Open the cursor menu",
                        shortcut: "⌘ + Left Click"
                    )
                    
                    ShortcutRow(
                        title: "Close Menu",
                        description: "Close the cursor menu",
                        shortcut: "⌘ + Left Click"
                    )
                    
                    ShortcutRow(
                        title: "Move Menu",
                        description: "Drag the menu to move it",
                        shortcut: "Drag outside buttons"
                    )
                    
                    ShortcutRow(
                        title: "Start Pencil Mode",
                        description: "Activate drawing mode",
                        shortcut: "Click pencil button"
                    )
                    
                    ShortcutRow(
                        title: "Stop Pencil Mode",
                        description: "Deactivate drawing mode",
                        shortcut: "⌘ + Left Click"
                    )
                }
                .padding(24)
            }
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}

struct ShortcutRow: View {
    let title: String
    let description: String
    let shortcut: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(shortcut)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                )
        }
    }
}

class ShortcutsWindow: NSWindowController {
    
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
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Keyboard Shortcuts"
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 500, height: 300)
        
        // Создаем SwiftUI view
        let shortcutsView = ShortcutsView(onClose: { [weak self] in
            self?.window?.close()
        })
        let hostingController = NSHostingController(rootView: shortcutsView)
        hostingController.view.frame = window.contentView!.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        
        window.contentView = hostingController.view
        
        // Устанавливаем делегат для обработки закрытия окна
        window.delegate = self
        
        self.window = window
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension ShortcutsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Окно закрывается, ничего не делаем
    }
}

