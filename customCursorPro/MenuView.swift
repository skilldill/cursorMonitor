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
                isActive: trailEnabled,
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
    var isActive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    @ObservedObject private var settings = CursorSettingsObservable()
    
    // iOS зеленый цвет (#34C759)
    private var iosGreen: Color {
        Color(red: 52/255.0, green: 199/255.0, blue: 89/255.0)
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(
                    isActive 
                        ? .white 
                        : (settings.isDark ? .primary : Color(white: 0.1))
                )
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(
                            isActive
                                ? iosGreen
                                : (isHovered
                                    ? (settings.isDark 
                                        ? Color.white.opacity(0.2) 
                                        : Color.black.opacity(0.2))
                                    : (settings.isDark 
                                        ? Color.white.opacity(0.1) 
                                        : Color.black.opacity(0.1)))
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
    private var isDragging = false
    private var dragStartLocation: NSPoint = .zero
    private var windowStartFrame: NSRect = .zero
    
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
        layer?.masksToBounds = false // Не обрезаем тень
        
        // Убеждаемся, что contentView не обрезает тень
        if let contentView = superview {
            contentView.wantsLayer = true
            contentView.layer?.masksToBounds = false
        }
        
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
    
    // MARK: - Drag and Drop
    
    override func mouseDown(with event: NSEvent) {
        // Проверяем, не кликнули ли на кнопку
        let location = convert(event.locationInWindow, from: nil)
        
        // Если клик не на кнопке, начинаем перетаскивание
        if !isPointOnButton(location) {
            isDragging = true
            dragStartLocation = NSEvent.mouseLocation // Используем глобальные координаты
            if let window = window {
                windowStartFrame = window.frame
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let window = window else { return }
        
        let currentLocation = NSEvent.mouseLocation // Используем глобальные координаты
        let deltaX = currentLocation.x - dragStartLocation.x
        let deltaY = currentLocation.y - dragStartLocation.y
        
        var newFrame = windowStartFrame
        newFrame.origin.x += deltaX
        newFrame.origin.y += deltaY
        
        // Ограничиваем перемещение границами всех экранов
        var screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
        for screen in NSScreen.screens {
            screenFrame = screenFrame.union(screen.visibleFrame)
        }
        
        newFrame.origin.x = max(screenFrame.minX, min(newFrame.origin.x, screenFrame.maxX - newFrame.width))
        newFrame.origin.y = max(screenFrame.minY, min(newFrame.origin.y, screenFrame.maxY - newFrame.height))
        
        window.setFrame(newFrame, display: true)
        
        // Обновляем позицию курсора при перетаскивании меню
        NotificationCenter.default.post(name: .cursorPositionUpdate, object: nil)
        
        // Обновляем начальную позицию для следующего движения
        dragStartLocation = currentLocation
        windowStartFrame = newFrame
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
    
    private func isPointOnButton(_ point: NSPoint) -> Bool {
        // Проверяем, находится ли точка в области кнопок
        // Кнопки находятся в центре view с отступом 16 пикселей с каждой стороны
        let buttonArea = bounds.insetBy(dx: 16, dy: 16)
        return buttonArea.contains(point)
    }
}
