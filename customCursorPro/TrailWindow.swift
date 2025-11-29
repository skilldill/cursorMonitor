import Cocoa

class TrailWindow: NSWindow {
    private var displayLink: CVDisplayLink?
    private var isDrawing = false
    
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
        _trailPoints.removeAll()
        // Убеждаемся, что окно видимо
        orderFrontRegardless()
        addTrailPoint(point)
        // Убеждаемся, что displayLink запущен
        if displayLink == nil {
            startDisplayLink()
        }
    }
    
    func addTrailPoint(_ point: NSPoint) {
        guard isDrawing else { return }
        // Убеждаемся, что окно видимо
        orderFrontRegardless()
        _trailPoints.append((point: point, timestamp: Date()))
        // Ограничиваем количество точек для производительности
        if _trailPoints.count > 1000 {
            _trailPoints.removeFirst(100)
        }
        // Убеждаемся, что displayLink запущен для обновления
        if displayLink == nil {
            startDisplayLink()
        }
        contentView?.needsDisplay = true
    }
    
    func endTrail() {
        isDrawing = false
        // Не останавливаем displayLink сразу, чтобы точки могли плавно исчезнуть
        // DisplayLink будет остановлен автоматически когда все точки исчезнут в updateTrails()
    }
    
    func clearTrails() {
        _trailPoints.removeAll()
        contentView?.needsDisplay = true
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
        let fadeDuration: TimeInterval = 0.5 // Время исчезновения в секундах
        
        // Удаляем старые точки
        _trailPoints.removeAll { point, timestamp in
            now.timeIntervalSince(timestamp) > fadeDuration
        }
        
        if !_trailPoints.isEmpty {
            contentView?.needsDisplay = true
        } else {
            // Если все точки исчезли и мы не рисуем, останавливаем displayLink
            if !isDrawing {
                stopDisplayLink()
            }
        }
    }
    
    var trailPoints: [(point: NSPoint, timestamp: Date)] {
        get {
            return _trailPoints
        }
        set {
            _trailPoints = newValue
        }
    }
    
    private var _trailPoints: [(point: NSPoint, timestamp: Date)] = []
    
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
            name: .cursorColorChanged,
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
            name: .outerLineWidthChanged,
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
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        let trailPoints = window.trailPoints
        guard trailPoints.count >= 2 else { 
            // Если точек меньше 2, но есть хотя бы одна, рисуем точку
            if trailPoints.count == 1 {
                let point = trailPoints[0]
                let now = Date()
                let fadeDuration: TimeInterval = 0.5
                let age = now.timeIntervalSince(point.timestamp)
                let alpha = max(0, 1.0 - (age / fadeDuration))
                
                if alpha > 0 {
                    let baseColor = CursorSettings.shared.color.color
                    let isGlowEnabled = CursorSettings.shared.cursorGlowEnabled
                    let opacity = CursorSettings.shared.opacity
                    let lineWidth = CursorSettings.shared.outerLineWidth
                    
                    ctx.saveGState()
                    ctx.setLineCap(.round)
                    ctx.setLineWidth(lineWidth)
                    
                    let path = CGMutablePath()
                    path.addEllipse(in: CGRect(x: point.point.x - lineWidth/2, y: point.point.y - lineWidth/2, width: lineWidth, height: lineWidth))
                    
                    if isGlowEnabled {
                        let shadowColor = baseColor.withAlphaComponent(opacity * alpha)
                        let blurRadius = lineWidth * 2.5
                        ctx.setShadow(offset: .zero, blur: blurRadius, color: shadowColor.cgColor)
                        ctx.addPath(path)
                        ctx.setFillColor(shadowColor.cgColor)
                        ctx.fillPath()
                        ctx.setShadow(offset: .zero, blur: 0, color: nil)
                        ctx.addPath(path)
                        ctx.setFillColor(NSColor.white.withAlphaComponent(opacity * alpha).cgColor)
                        ctx.fillPath()
                    } else {
                        ctx.addPath(path)
                        ctx.setFillColor(baseColor.withAlphaComponent(opacity * alpha).cgColor)
                        ctx.fillPath()
                    }
                    
                    ctx.restoreGState()
                }
            }
            return 
        }
        
        let now = Date()
        let fadeDuration: TimeInterval = 0.5
        
        // Получаем настройки цвета и эффекта свечения
        let baseColor = CursorSettings.shared.color.color
        let isGlowEnabled = CursorSettings.shared.cursorGlowEnabled
        let opacity = CursorSettings.shared.opacity
        let lineWidth = CursorSettings.shared.outerLineWidth
        
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(lineWidth)
        
        // Рисуем линии между точками с эффектом исчезновения
        for i in 0..<trailPoints.count - 1 {
            let point1 = trailPoints[i]
            let point2 = trailPoints[i + 1]
            
            let age1 = now.timeIntervalSince(point1.timestamp)
            let age2 = now.timeIntervalSince(point2.timestamp)
            
            // Вычисляем прозрачность на основе возраста точки
            let alpha1 = max(0, 1.0 - (age1 / fadeDuration))
            let alpha2 = max(0, 1.0 - (age2 / fadeDuration))
            
            // Используем среднюю прозрачность для сегмента
            let segmentAlpha = (alpha1 + alpha2) / 2.0
            
            if segmentAlpha > 0 {
                let path = CGMutablePath()
                path.move(to: point1.point)
                path.addLine(to: point2.point)
                
                if isGlowEnabled {
                    // Рисуем с эффектом свечения
                    let shadowColor = baseColor.withAlphaComponent(opacity * segmentAlpha)
                    let blurRadius = lineWidth * 2.5
                    ctx.setShadow(
                        offset: .zero,
                        blur: blurRadius,
                        color: shadowColor.cgColor
                    )
                    
                    ctx.addPath(path)
                    ctx.setStrokeColor(shadowColor.cgColor)
                    ctx.strokePath()
                    
                    ctx.setShadow(offset: .zero, blur: 0, color: nil)
                    
                    ctx.addPath(path)
                    ctx.setStrokeColor(NSColor.white.withAlphaComponent(opacity * segmentAlpha).cgColor)
                    ctx.setLineWidth(lineWidth * 0.7)
                    ctx.strokePath()
                } else {
                    // Обычная линия
                    ctx.addPath(path)
                    ctx.setStrokeColor(baseColor.withAlphaComponent(opacity * segmentAlpha).cgColor)
                    ctx.strokePath()
                }
            }
        }
        
        ctx.restoreGState()
    }
}


