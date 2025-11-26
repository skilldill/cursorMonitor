import Cocoa

// Общий менеджер состояния рисования для синхронизации между всеми экранами
class DrawingStateManager {
    static let shared = DrawingStateManager()
    
    private var paths: [DrawingPath] = []
    private var currentPathPoints: [NSPoint] = [] // Текущий путь как массив глобальных точек
    private var currentPathColor: NSColor = CursorSettings.shared.pencilColor.color
    private var currentPathOpacity: CGFloat = CursorSettings.shared.pencilOpacity
    private var isDrawing = false
    
    private var observers: [DrawingView] = []
    
    private init() {}
    
    func addObserver(_ view: DrawingView) {
        observers.append(view)
    }
    
    func removeObserver(_ view: DrawingView) {
        observers.removeAll { $0 === view }
    }
    
    func notifyObservers() {
        observers.forEach { $0.needsDisplay = true }
    }
    
    func startPath(at location: NSPoint) {
        isDrawing = true
        currentPathPoints = [location] // Начинаем с первой точки
        
        currentPathColor = CursorSettings.shared.pencilColor.color
        currentPathOpacity = CursorSettings.shared.pencilOpacity
        notifyObservers()
    }
    
    func addPointToPath(_ location: NSPoint) {
        guard isDrawing else { return }
        currentPathPoints.append(location)
        notifyObservers()
    }
    
    func endPath() {
        guard isDrawing, !currentPathPoints.isEmpty else { return }
        isDrawing = false
        
        // Сохраняем завершенный путь
        paths.append(DrawingPath(
            points: currentPathPoints,
            color: currentPathColor,
            opacity: currentPathOpacity,
            lineWidth: CursorSettings.shared.pencilLineWidth
        ))
        
        currentPathPoints.removeAll()
        notifyObservers()
    }
    
    func clear() {
        paths.removeAll()
        currentPathPoints.removeAll()
        isDrawing = false
        notifyObservers()
    }
    
    func getPaths() -> [DrawingPath] {
        return paths
    }
    
    func getCurrentPathPoints() -> [NSPoint] {
        return currentPathPoints
    }
    
    func getCurrentPathColor() -> NSColor {
        return currentPathColor
    }
    
    func getCurrentPathOpacity() -> CGFloat {
        return currentPathOpacity
    }
    
    func getIsDrawing() -> Bool {
        return isDrawing
    }
}

class DrawingWindow {
    private var windows: [NSWindow] = []
    private var drawingViews: [DrawingView] = []
    private var isActive = false
    var onStopDrawing: (() -> Void)?
    
    func startDrawing() {
        guard !isActive else { return }
        isActive = true
        
        // Получаем все экраны
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        // Создаем отдельное окно для каждого экрана
        for screen in screens {
            let screenFrame = screen.frame
            
            let panel = NSPanel(
                contentRect: screenFrame,
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
            
            let view = DrawingView(frame: NSRect(x: 0, y: 0, width: screenFrame.width, height: screenFrame.height))
            view.wantsLayer = true
            view.screenFrame = screenFrame
            view.onStopDrawing = { [weak self] in
                self?.stopDrawing()
                self?.onStopDrawing?()
            }
            
            // Регистрируем view в менеджере состояния
            DrawingStateManager.shared.addObserver(view)
            
            panel.contentView = view
            
            windows.append(panel)
            drawingViews.append(view)
            
            panel.orderFrontRegardless()
        }
    }
    
    func stopDrawing() {
        guard isActive else { return }
        isActive = false
        
        // Удаляем все views из менеджера состояния
        for view in drawingViews {
            DrawingStateManager.shared.removeObserver(view)
        }
        
        // Закрываем все окна
        for window in windows {
            window.orderOut(nil)
        }
        
        windows.removeAll()
        drawingViews.removeAll()
        
        // Очищаем состояние рисования
        DrawingStateManager.shared.clear()
    }
    
    func clearDrawing() {
        DrawingStateManager.shared.clear()
    }
    
    var isDrawing: Bool {
        return isActive
    }
}

struct DrawingPath {
    let points: [NSPoint] // Глобальные координаты точек
    let color: NSColor
    let opacity: CGFloat
    let lineWidth: CGFloat
    
    func createBezierPath(for screenFrame: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        guard !points.isEmpty else { return path }
        
        // Преобразуем первую точку из глобальных в локальные координаты
        let firstPoint = NSPoint(
            x: points[0].x - screenFrame.origin.x,
            y: points[0].y - screenFrame.origin.y
        )
        path.move(to: firstPoint)
        
        // Добавляем остальные точки
        for i in 1..<points.count {
            let localPoint = NSPoint(
                x: points[i].x - screenFrame.origin.x,
                y: points[i].y - screenFrame.origin.y
            )
            path.line(to: localPoint)
        }
        
        return path
    }
    
    func intersects(screenFrame: NSRect) -> Bool {
        // Проверяем, есть ли хотя бы одна точка пути в пределах экрана
        return points.contains { screenFrame.contains($0) }
    }
}

class DrawingView: NSView {
    var screenFrame: NSRect = .zero
    var onStopDrawing: (() -> Void)?
    
    private let stateManager = DrawingStateManager.shared
    
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
        needsDisplay = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stateManager.removeObserver(self)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        // Если нажата Command, отключаем карандаш
        if event.modifierFlags.contains(.command) {
            onStopDrawing?()
            return
        }
        
        // Получаем глобальные координаты мыши
        let globalLocation = NSEvent.mouseLocation
        
        // Начинаем путь через менеджер состояния
        stateManager.startPath(at: globalLocation)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        guard stateManager.getIsDrawing() else { return }
        
        // Получаем глобальные координаты мыши
        let globalLocation = NSEvent.mouseLocation
        
        // Добавляем точку через менеджер состояния
        stateManager.addPointToPath(globalLocation)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        guard stateManager.getIsDrawing() else { return }
        
        // Завершаем путь через менеджер состояния
        stateManager.endPath()
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
        
        // Получаем все пути из менеджера состояния
        let paths = stateManager.getPaths()
        let currentPathPoints = stateManager.getCurrentPathPoints()
        let currentPathColor = stateManager.getCurrentPathColor()
        let currentPathOpacity = stateManager.getCurrentPathOpacity()
        
        // Рисуем все сохраненные пути с их цветами и прозрачностью
        for drawingPath in paths {
            // Проверяем, пересекается ли путь с текущим экраном
            if drawingPath.intersects(screenFrame: screenFrame) {
                // Создаем путь в локальных координатах для текущего экрана
                let localPath = drawingPath.createBezierPath(for: screenFrame)
                
                drawingPath.color.withAlphaComponent(drawingPath.opacity).setStroke()
                localPath.stroke()
            }
        }
        
        // Рисуем текущий путь, если он есть
        if !currentPathPoints.isEmpty && stateManager.getIsDrawing() {
            // Проверяем, есть ли хотя бы одна точка пути на этом экране или рядом
            let hasRelevantPoints = currentPathPoints.contains { point in
                screenFrame.contains(point) || 
                screenFrame.insetBy(dx: -100, dy: -100).contains(point)
            }
            
            if hasRelevantPoints {
                let localPath = NSBezierPath()
                localPath.lineWidth = CursorSettings.shared.pencilLineWidth
                localPath.lineCapStyle = .round
                localPath.lineJoinStyle = .round
                
                // Преобразуем все точки в локальные координаты
                for (index, point) in currentPathPoints.enumerated() {
                    let localPoint = NSPoint(
                        x: point.x - screenFrame.origin.x,
                        y: point.y - screenFrame.origin.y
                    )
                    
                    if index == 0 {
                        localPath.move(to: localPoint)
                    } else {
                        localPath.line(to: localPoint)
                    }
                }
                
                currentPathColor.withAlphaComponent(currentPathOpacity).setStroke()
                localPath.stroke()
            }
        }
    }
}

