import Cocoa

class DrawingWindow {
    private var window: NSWindow?
    private var drawingView: DrawingView?
    private var isActive = false
    var onStopDrawing: (() -> Void)?
    
    func startDrawing() {
        guard !isActive else { return }
        isActive = true
        
        // Получаем все экраны и находим общий фрейм
        let screens = NSScreen.screens
        guard let firstScreen = screens.first else { return }
        
        // Вычисляем общий фрейм для всех экранов
        var unionFrame = firstScreen.frame
        for screen in screens {
            unionFrame = unionFrame.union(screen.frame)
        }
        
        // Создаем окно на весь экран
        let panel = NSPanel(
            contentRect: unionFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.level = .screenSaver
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        
        let view = DrawingView(frame: unionFrame)
        view.wantsLayer = true
        view.onStopDrawing = { [weak self] in
            self?.stopDrawing()
            self?.onStopDrawing?()
        }
        panel.contentView = view
        
        self.window = panel
        self.drawingView = view
        
        panel.orderFrontRegardless()
    }
    
    func stopDrawing() {
        guard isActive else { return }
        isActive = false
        
        window?.orderOut(nil)
        window = nil
        drawingView = nil
    }
    
    func clearDrawing() {
        drawingView?.clear()
    }
    
    var isDrawing: Bool {
        return isActive
    }
}

struct DrawingPath {
    let path: NSBezierPath
    let color: NSColor
    let opacity: CGFloat
}

class DrawingView: NSView {
    private var paths: [DrawingPath] = []
    private var currentPath: NSBezierPath?
    private var currentPathColor: NSColor = CursorSettings.shared.pencilColor.color
    private var currentPathOpacity: CGFloat = CursorSettings.shared.pencilOpacity
    private var isDrawing = false
    var onStopDrawing: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pencilSettingsChanged),
            name: .pencilColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pencilSettingsChanged),
            name: .pencilLineWidthChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pencilSettingsChanged),
            name: .pencilOpacityChanged,
            object: nil
        )
    }
    
    @objc private func pencilSettingsChanged() {
        // Обновляем текущие значения для новых путей
        currentPathColor = CursorSettings.shared.pencilColor.color
        currentPathOpacity = CursorSettings.shared.pencilOpacity
        needsDisplay = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func clear() {
        paths.removeAll()
        currentPath = nil
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        // Если нажата Command, отключаем карандаш
        if event.modifierFlags.contains(.command) {
            onStopDrawing?()
            return
        }
        
        isDrawing = true
        
        // Используем координаты относительно окна
        let location = event.locationInWindow
        
        currentPath = NSBezierPath()
        currentPath?.lineWidth = CursorSettings.shared.pencilLineWidth
        currentPath?.lineCapStyle = .round
        currentPath?.lineJoinStyle = .round
        currentPath?.move(to: location)
        
        // Обновляем текущие значения цвета и прозрачности
        currentPathColor = CursorSettings.shared.pencilColor.color
        currentPathOpacity = CursorSettings.shared.pencilOpacity
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        guard isDrawing, let path = currentPath else { return }
        
        // Используем координаты относительно окна
        let location = event.locationInWindow
        
        path.line(to: location)
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        guard isDrawing, let path = currentPath else { return }
        
        isDrawing = false
        paths.append(DrawingPath(path: path, color: currentPathColor, opacity: currentPathOpacity))
        currentPath = nil
        needsDisplay = true
    }
    
    override func otherMouseDown(with event: NSEvent) {
        super.otherMouseDown(with: event)
        // Если нажато колесико мыши (buttonNumber == 2), отключаем карандаш
        if event.buttonNumber == 2 {
            onStopDrawing?()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Рисуем все сохраненные пути с их цветами и прозрачностью
        for drawingPath in paths {
            drawingPath.color.withAlphaComponent(drawingPath.opacity).setStroke()
            drawingPath.path.stroke()
        }
        
        // Рисуем текущий путь, если он есть
        if let currentPath = currentPath {
            currentPathColor.withAlphaComponent(currentPathOpacity).setStroke()
            currentPath.stroke()
        }
    }
}

