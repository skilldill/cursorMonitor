import Cocoa

// Структура для хранения пути трека с временной меткой
struct TrailPath {
    let points: [NSPoint] // Глобальные координаты точек
    let startTime: Date
    let color: NSColor
    let opacity: CGFloat
    let lineWidth: CGFloat
}

class TrailWindow: NSWindow {
    private var displayLink: CVDisplayLink?
    private var isDrawing = false
    private var currentPathPoints: [NSPoint] = [] // Текущий путь как массив глобальных точек
    private var completedPaths: [TrailPath] = [] // Завершенные пути с временными метками
    var screenFrame: NSRect = .zero // Frame экрана для этого окна
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        
        // Создаем view с правильным frame (используем frame окна)
        let view = TrailView(frame: frame)
        view.autoresizingMask = [.width, .height]
        contentView = view
    }
    
    func startTrail(at point: NSPoint) {
        isDrawing = true
        currentPathPoints = [point] // Начинаем новый путь
        // Убеждаемся, что окно видимо
        orderFrontRegardless()
        // Убеждаемся, что displayLink запущен
        if displayLink == nil {
            startDisplayLink()
        }
        contentView?.needsDisplay = true
    }
    
    func addTrailPoint(_ point: NSPoint) {
        guard isDrawing else { return }
        // Убеждаемся, что окно видимо
        orderFrontRegardless()
        currentPathPoints.append(point)
        // Ограничиваем количество точек для производительности
        if currentPathPoints.count > 1000 {
            currentPathPoints.removeFirst(100)
        }
        // Убеждаемся, что displayLink запущен для обновления
        if displayLink == nil {
            startDisplayLink()
        }
        contentView?.needsDisplay = true
    }
    
    func endTrail() {
        guard isDrawing, !currentPathPoints.isEmpty else { return }
        isDrawing = false
        
        // Сохраняем завершенный путь с временной меткой
        let trailPath = TrailPath(
            points: currentPathPoints,
            startTime: Date(),
            color: CursorSettings.shared.clickColor.color,
            opacity: CursorSettings.shared.opacity,
            lineWidth: CursorSettings.shared.trailLineWidth
        )
        completedPaths.append(trailPath)
        
        currentPathPoints.removeAll()
        // Не останавливаем displayLink сразу, чтобы пути могли плавно исчезнуть
        // DisplayLink будет остановлен автоматически когда все пути исчезнут в updateTrails()
    }
    
    func clearTrails() {
        currentPathPoints.removeAll()
        completedPaths.removeAll()
        contentView?.needsDisplay = true
        stopDisplayLink()
    }
    
    private func startDisplayLink() {
        stopDisplayLink()
        
        var displayLink: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        if let displayLink = displayLink {
            self.displayLink = displayLink
            
            let callback: CVDisplayLinkOutputCallback = { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
                let trailWindow = Unmanaged<TrailWindow>.fromOpaque(context!).takeUnretainedValue()
                DispatchQueue.main.async {
                    trailWindow.updateTrails()
                }
                return kCVReturnSuccess
            }
            
            CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())
            CVDisplayLinkStart(displayLink)
        }
    }
    
    private func stopDisplayLink() {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }
    }
    
    private func updateTrails() {
        let now = Date()
        let fadeDuration = CursorSettings.shared.trailFadeDuration // Время исчезновения из настроек
        
        // Удаляем старые пути
        completedPaths.removeAll { path in
            now.timeIntervalSince(path.startTime) > fadeDuration
        }
        
        if !completedPaths.isEmpty || !currentPathPoints.isEmpty {
            contentView?.needsDisplay = true
        } else {
            // Если все пути исчезли и мы не рисуем, останавливаем displayLink
            if !isDrawing {
                stopDisplayLink()
            }
        }
    }
    
    // Геттеры для TrailView
    func getCurrentPathPoints() -> [NSPoint] {
        return currentPathPoints
    }
    
    func getCompletedPaths() -> [TrailPath] {
        return completedPaths
    }
    
    func getIsDrawing() -> Bool {
        return isDrawing
    }
    
}

class TrailView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .cursorGlowEnabledChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .cursorClickColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .cursorOpacityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .trailLineWidthChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .trailFadeDurationChanged,
            object: nil
        )
    }
    
    @objc private func settingsChanged() {
        needsDisplay = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let window = window as? TrailWindow else { return }
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let now = Date()
        let fadeDuration = CursorSettings.shared.trailFadeDuration
        let isGlowEnabled = CursorSettings.shared.cursorGlowEnabled
        
        // Получаем frame окна для преобразования координат
        let windowFrame = window.frame
        
        // Рисуем все завершенные пути с fade-out эффектом
        let completedPaths = window.getCompletedPaths()
        let screenFrame = window.screenFrame
        
        for trailPath in completedPaths {
            let age = now.timeIntervalSince(trailPath.startTime)
            let alpha = max(0, 1.0 - (age / fadeDuration))
            
            if alpha > 0 && !trailPath.points.isEmpty {
                // Расширяем frame экрана на толщину линии, чтобы включить точки на границах
                let expandedFrame = screenFrame.insetBy(dx: -trailPath.lineWidth, dy: -trailPath.lineWidth)
                
                // Фильтруем точки, которые находятся в пределах этого экрана (включая границы)
                let filteredPoints = trailPath.points.filter { point in
                    expandedFrame.contains(point)
                }
                
                guard !filteredPoints.isEmpty else { continue }
                
                // Создаем NSBezierPath из точек (как в карандаше)
                let bezierPath = NSBezierPath()
                bezierPath.lineWidth = trailPath.lineWidth
                bezierPath.lineCapStyle = .round
                bezierPath.lineJoinStyle = .round
                
                // Преобразуем точки из глобальных координат в локальные координаты окна
                for (index, point) in filteredPoints.enumerated() {
                    let localPoint = NSPoint(
                        x: point.x - windowFrame.origin.x,
                        y: point.y - windowFrame.origin.y
                    )
                    
                    if index == 0 {
                        bezierPath.move(to: localPoint)
                    } else {
                        bezierPath.line(to: localPoint)
                    }
                }
                
                // Рисуем путь с учетом fade-out и эффекта свечения (как карандаш)
                if isGlowEnabled {
                    drawGlowingPath(context: context, path: bezierPath, color: trailPath.color, opacity: trailPath.opacity * alpha, lineWidth: trailPath.lineWidth)
                } else {
                    // Обычная цветная линия с fade-out
                    trailPath.color.withAlphaComponent(trailPath.opacity * alpha).setStroke()
                    bezierPath.stroke()
                }
            }
        }
        
        // Рисуем текущий путь, если он есть (без fade-out, так как он еще рисуется)
        let currentPathPoints = window.getCurrentPathPoints()
        if !currentPathPoints.isEmpty && window.getIsDrawing() {
            // Расширяем frame экрана на толщину линии, чтобы включить точки на границах
            let lineWidth = CursorSettings.shared.trailLineWidth
            let expandedFrame = screenFrame.insetBy(dx: -lineWidth, dy: -lineWidth)
            
            // Фильтруем точки, которые находятся в пределах этого экрана (включая границы)
            let filteredPoints = currentPathPoints.filter { point in
                expandedFrame.contains(point)
            }
            
            guard !filteredPoints.isEmpty else { return }
            
            let bezierPath = NSBezierPath()
            bezierPath.lineWidth = CursorSettings.shared.trailLineWidth
            bezierPath.lineCapStyle = .round
            bezierPath.lineJoinStyle = .round
            
            let baseColor = CursorSettings.shared.clickColor.color
            let opacity = CursorSettings.shared.opacity
            
            // Преобразуем точки из глобальных координат в локальные координаты окна
            for (index, point) in filteredPoints.enumerated() {
                let localPoint = NSPoint(
                    x: point.x - windowFrame.origin.x,
                    y: point.y - windowFrame.origin.y
                )
                
                if index == 0 {
                    bezierPath.move(to: localPoint)
                } else {
                    bezierPath.line(to: localPoint)
                }
            }
            
            // Рисуем текущий путь (как карандаш)
            if isGlowEnabled {
                drawGlowingPath(context: context, path: bezierPath, color: baseColor, opacity: opacity, lineWidth: CursorSettings.shared.trailLineWidth)
            } else {
                // Обычная цветная линия
                baseColor.withAlphaComponent(opacity).setStroke()
                bezierPath.stroke()
            }
        }
    }
    
    // Рисует путь с эффектом свечения: белая линия с цветной тенью (как в карандаше)
    private func drawGlowingPath(context: CGContext, path: NSBezierPath, color: NSColor, opacity: CGFloat, lineWidth: CGFloat) {
        context.saveGState()
        
        // Создаем CGPath из NSBezierPath
        let cgPath = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        
        for i in 0..<path.elementCount {
            let element = path.element(at: i, associatedPoints: &points)
            
            switch element {
            case .moveTo:
                cgPath.move(to: points[0])
            case .lineTo:
                cgPath.addLine(to: points[0])
            case .curveTo:
                cgPath.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                cgPath.closeSubpath()
            @unknown default:
                break
            }
        }
        
        // Настраиваем параметры линии
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Рисуем цветную тень (размытие)
        let shadowColor = color.withAlphaComponent(opacity)
        context.setShadow(
            offset: .zero,
            blur: lineWidth * 2.5, // Размытие пропорционально толщине линии
            color: shadowColor.cgColor
        )
        
        // Рисуем тень
        context.addPath(cgPath)
        context.setStrokeColor(shadowColor.cgColor)
        context.strokePath()
        
        // Отключаем тень для белой линии
        context.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Рисуем белую линию поверх тени
        context.addPath(cgPath)
        context.setStrokeColor(NSColor.white.withAlphaComponent(opacity).cgColor)
        context.setLineWidth(lineWidth * 0.7) // Немного тоньше для лучшего эффекта
        context.strokePath()
        
        context.restoreGState()
    }
}


