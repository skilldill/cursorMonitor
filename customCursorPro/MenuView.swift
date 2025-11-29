import SwiftUI
import Cocoa

struct MenuViewSwiftUI: View {
    @ObservedObject private var settings = CursorSettingsObservable()
    @State private var trailEnabled = CursorSettings.shared.cursorTrailEnabled
    
    var onPencilClick: (() -> Void)?
    var onTrailToggle: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Кнопка карандаша
            MenuButton(
                icon: "pencil.tip",
                action: {
                    onPencilClick?()
                }
            )
            
            // Кнопка следа
            MenuButton(
                icon: "waveform.path.ecg",
                opacity: trailEnabled ? 1.0 : 0.5,
                action: {
                    let newValue = !CursorSettings.shared.cursorTrailEnabled
                    CursorSettings.shared.cursorTrailEnabled = newValue
                    trailEnabled = newValue
                    onTrailToggle?()
                }
            )
        }
        .padding(16)
        .background(
            VisualEffectView(material: settings.isDark ? .hudWindow : .light)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(settings.isDark ? 0.3 : 0.15), radius: 10, x: 0, y: -2)
        )
        .frame(width: 176, height: 80)
        .onReceive(NotificationCenter.default.publisher(for: .cursorTrailEnabledChanged)) { _ in
            trailEnabled = CursorSettings.shared.cursorTrailEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuThemeChanged)) { _ in
            // Обновляем view при изменении темы
        }
    }
}

struct MenuButton: View {
    let icon: String
    var opacity: CGFloat = 1.0
    let action: () -> Void
    
    @State private var isHovered = false
    @ObservedObject private var settings = CursorSettingsObservable()
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(settings.isDark ? .primary : Color(white: 0.1))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(
                            isHovered
                                ? (settings.isDark 
                                    ? Color.white.opacity(0.2) 
                                    : Color.black.opacity(0.2))
                                : (settings.isDark 
                                    ? Color.white.opacity(0.1) 
                                    : Color.black.opacity(0.1))
                        )
                )
                .opacity(opacity)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// NSVisualEffectView wrapper для SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

// Обертка для использования в AppKit
class MenuViewWrapper: NSView {
    private var hostingView: NSHostingView<MenuViewSwiftUI>?
    
    var onPencilClick: (() -> Void)? {
        didSet {
            updateHostingView()
        }
    }
    
    var onTrailToggle: (() -> Void)? {
        didSet {
            updateHostingView()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 16
        updateHostingView()
        
        // Подписываемся на изменения темы
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: .menuThemeChanged,
            object: nil
        )
    }
    
    @objc private func themeChanged() {
        updateHostingView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateHostingView() {
        // Удаляем старый view
        hostingView?.removeFromSuperview()
        
        // Создаем новый SwiftUI view
        let menuView = MenuViewSwiftUI(
            onPencilClick: onPencilClick,
            onTrailToggle: onTrailToggle
        )
        
        let hostingView = NSHostingView(rootView: menuView)
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        
        addSubview(hostingView)
        self.hostingView = hostingView
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        hostingView?.frame = bounds
    }
}
