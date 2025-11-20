import Cocoa

final class HighlightView: NSView {

    // Базовый цвет подсветки (можно менять)
    var baseColor: NSColor = CursorSettings.shared.color.color {
        didSet {
            needsDisplay = true
        }
    }
    // Цвет при клике
    var clickColor: NSColor = CursorSettings.shared.clickColor.color {
        didSet {
            needsDisplay = true
        }
    }
    
    // Прозрачность курсора
    var opacity: CGFloat = CursorSettings.shared.opacity {
        didSet {
            needsDisplay = true
        }
    }

    // Текущее состояние
    private var isPulsing = false
    
    // Режим карандаша
    var isPencilMode: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    // Цвет карандаша для режима карандаша
    var pencilModeColor: NSColor = CursorSettings.shared.pencilColor.color {
        didSet {
            if isPencilMode {
                needsDisplay = true
            }
        }
    }

    // Коэффициент масштаба фигуры (1.0 — полный размер)
    private var currentScale: CGFloat = 1.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    // Обработчик клика для разморозки курсора
    var onClick: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(colorChanged),
            name: .cursorColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(opacityChanged),
            name: .cursorOpacityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clickColorChanged),
            name: .cursorClickColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pencilColorChanged),
            name: .pencilColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pencilLineWidthChanged),
            name: .pencilLineWidthChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shapeChanged),
            name: .cursorShapeChanged,
            object: nil
        )
    }
    
    @objc private func colorChanged() {
        baseColor = CursorSettings.shared.color.color
    }
    
    @objc private func opacityChanged() {
        opacity = CursorSettings.shared.opacity
    }
    
    @objc private func clickColorChanged() {
        clickColor = CursorSettings.shared.clickColor.color
    }
    
    @objc private func pencilColorChanged() {
        pencilModeColor = CursorSettings.shared.pencilColor.color
    }
    
    @objc private func pencilLineWidthChanged() {
        if isPencilMode {
            needsDisplay = true
        }
    }
    
    @objc private func shapeChanged() {
        needsDisplay = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.clear(bounds)

        // Режим карандаша - маленькая окружность
        if isPencilMode {
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            // Радиус равен половине толщины карандаша из настроек
            let radius = CursorSettings.shared.pencilLineWidth / 2
            let circlePath = CGMutablePath()
            circlePath.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            
            ctx.addPath(circlePath)
            ctx.setFillColor(pencilModeColor.withAlphaComponent(CursorSettings.shared.pencilOpacity).cgColor)
            ctx.fillPath()
            
            // Обводка для лучшей видимости
            ctx.addPath(circlePath)
            ctx.setStrokeColor(pencilModeColor.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokePath()
            return
        }

        let base = (isPulsing ? clickColor : baseColor).withAlphaComponent(opacity)

        // Параметры линий
        let outerLineWidth: CGFloat = 10
        let innerLineWidth: CGFloat = 8

        // Немного отступим от краёв
        let inset: CGFloat = 12

        // Прямоугольник, в который впишем фигуру
        let rect = bounds.insetBy(dx: inset, dy: inset)
        // МАСШТАБИРУЕМ сам размер, а не слой
        let size = min(rect.width, rect.height) * currentScale

        ctx.saveGState()
        ctx.translateBy(x: bounds.midX, y: bounds.midY)
        
        let shape = CursorSettings.shared.shape
        
        // Рисуем форму в зависимости от выбранной
        switch shape {
        case .squircle:
            drawSquircle(ctx: ctx, size: size, base: base, outerLineWidth: outerLineWidth, innerLineWidth: innerLineWidth)
        case .circle:
            drawCircle(ctx: ctx, size: size, base: base, outerLineWidth: outerLineWidth, innerLineWidth: innerLineWidth)
        case .hexagon:
            drawHexagon(ctx: ctx, size: size, base: base, outerLineWidth: outerLineWidth, innerLineWidth: innerLineWidth)
        case .triangle:
            drawTriangle(ctx: ctx, size: size, base: base, outerLineWidth: outerLineWidth, innerLineWidth: innerLineWidth)
        case .rhombus:
            drawRhombus(ctx: ctx, size: size, base: base, outerLineWidth: outerLineWidth, innerLineWidth: innerLineWidth)
        }

        ctx.restoreGState()
    }

    // MARK: - Клик

    /// Вызывается при mouseDown
    func beginClick() {
        isPulsing = true
        currentScale = 0.9   // чуть уменьшаем фигуру
    }

    /// Вызывается при mouseUp
    func endClick() {
        isPulsing = false
        currentScale = 1.0   // возвращаем нормальный размер
    }

    // Старый "пульс" можно оставить на случай использования где-то ещё
    func pulse() {
        isPulsing = true
        currentScale = 0.9

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.isPulsing = false
            self?.currentScale = 1.0
        }
    }

    // На случай если что-то пошло не так
    private func simplePulseFallback() {
        isPulsing = true
        currentScale = 0.9
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.isPulsing = false
            self?.currentScale = 1.0
        }
    }
    
    // MARK: - Отрисовка форм
    
    private func drawSquircle(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let cornerRadius = size / 3.5 // Сильно скругленные углы
        
        // Внешнее кольцо
        let outerPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Внутреннее кольцо
        let innerInset: CGFloat = 8
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: max(cornerRadius - innerInset / 2, 0), cornerHeight: max(cornerRadius - innerInset / 2, 0), transform: nil)
        ctx.addPath(innerPath)
        ctx.setStrokeColor(base.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(innerLineWidth)
        ctx.strokePath()
    }
    
    private func drawCircle(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Используем rounded rect с большим cornerRadius для более мягкого вида
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let cornerRadius = size / 2 // Максимальное скругление для круга
        
        // Внешнее кольцо
        let outerPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Внутреннее кольцо
        let innerInset: CGFloat = 8
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: max(cornerRadius - innerInset / 2, 0), cornerHeight: max(cornerRadius - innerInset / 2, 0), transform: nil)
        ctx.addPath(innerPath)
        ctx.setStrokeColor(base.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(innerLineWidth)
        ctx.strokePath()
    }
    
    private func drawHexagon(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Увеличиваем радиус для более длинных граней (примерно на 20%)
        let radius = size / 2 * 1.2
        let cornerRadius = size / 4.5 // Увеличенное скругление углов, пропорционально размеру
        
        // Внешний шестиугольник
        let outerPath = createRoundedHexagonPath(radius: radius, cornerRadius: cornerRadius)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Внутренний шестиугольник
        let innerInset: CGFloat = 8
        let innerRadius = radius - innerInset
        let innerPath = createRoundedHexagonPath(radius: innerRadius, cornerRadius: max(cornerRadius - innerInset / 2, 0))
        ctx.addPath(innerPath)
        ctx.setStrokeColor(base.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(innerLineWidth)
        ctx.strokePath()
    }
    
    private func createRoundedHexagonPath(radius: CGFloat, cornerRadius: CGFloat) -> CGMutablePath {
        let path = CGMutablePath()
        let sides = 6
        let angle = .pi * 2 / CGFloat(sides)
        
        // Вычисляем точки для скругленных углов
        var points: [CGPoint] = []
        for i in 0..<sides {
            let currentAngle = angle * CGFloat(i) - .pi / 2
            let x = cos(currentAngle) * radius
            let y = sin(currentAngle) * radius
            points.append(CGPoint(x: x, y: y))
        }
        
        // Создаем путь со скругленными углами
        for i in 0..<sides {
            let currentPoint = points[i]
            let nextPoint = points[(i + 1) % sides]
            let prevPoint = points[(i - 1 + sides) % sides]
            
            // Вычисляем точки начала и конца скругления
            let toCurrent = CGPoint(x: currentPoint.x - prevPoint.x, y: currentPoint.y - prevPoint.y)
            let toNext = CGPoint(x: nextPoint.x - currentPoint.x, y: nextPoint.y - currentPoint.y)
            let dist1 = sqrt(toCurrent.x * toCurrent.x + toCurrent.y * toCurrent.y)
            let dist2 = sqrt(toNext.x * toNext.x + toNext.y * toNext.y)
            
            let startX = currentPoint.x - toCurrent.x / dist1 * cornerRadius
            let startY = currentPoint.y - toCurrent.y / dist1 * cornerRadius
            let endX = currentPoint.x + toNext.x / dist2 * cornerRadius
            let endY = currentPoint.y + toNext.y / dist2 * cornerRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: startX, y: startY))
            } else {
                path.addLine(to: CGPoint(x: startX, y: startY))
            }
            
            // Добавляем дугу для скругления угла
            path.addQuadCurve(to: CGPoint(x: endX, y: endY), control: currentPoint)
        }
        path.closeSubpath()
        return path
    }
    
    private func drawTriangle(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Увеличиваем радиус для более длинных сторон (примерно на 20%)
        let radius = size / 2 * 1.2
        let cornerRadius = size / 4.5 // Увеличенное скругление углов, пропорционально размеру
        
        // Внешний треугольник
        let outerPath = createRoundedTrianglePath(radius: radius, cornerRadius: cornerRadius)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Внутренний треугольник
        let innerInset: CGFloat = 8
        let innerRadius = radius - innerInset
        let innerPath = createRoundedTrianglePath(radius: innerRadius, cornerRadius: max(cornerRadius - innerInset / 2, 0))
        ctx.addPath(innerPath)
        ctx.setStrokeColor(base.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(innerLineWidth)
        ctx.strokePath()
    }
    
    private func createRoundedTrianglePath(radius: CGFloat, cornerRadius: CGFloat) -> CGMutablePath {
        let path = CGMutablePath()
        let sides = 3
        let angle = .pi * 2 / CGFloat(sides)
        
        // Вычисляем точки для скругленных углов
        // Переворачиваем треугольник: добавляем pi для поворота на 180 градусов
        var points: [CGPoint] = []
        for i in 0..<sides {
            let currentAngle = angle * CGFloat(i) - .pi / 2 + .pi
            let x = cos(currentAngle) * radius
            let y = sin(currentAngle) * radius
            points.append(CGPoint(x: x, y: y))
        }
        
        // Создаем путь со скругленными углами
        for i in 0..<sides {
            let currentPoint = points[i]
            let nextPoint = points[(i + 1) % sides]
            let prevPoint = points[(i - 1 + sides) % sides]
            
            // Вычисляем точки начала и конца скругления
            let toCurrent = CGPoint(x: currentPoint.x - prevPoint.x, y: currentPoint.y - prevPoint.y)
            let toNext = CGPoint(x: nextPoint.x - currentPoint.x, y: nextPoint.y - currentPoint.y)
            let dist1 = sqrt(toCurrent.x * toCurrent.x + toCurrent.y * toCurrent.y)
            let dist2 = sqrt(toNext.x * toNext.x + toNext.y * toNext.y)
            
            let startX = currentPoint.x - toCurrent.x / dist1 * cornerRadius
            let startY = currentPoint.y - toCurrent.y / dist1 * cornerRadius
            let endX = currentPoint.x + toNext.x / dist2 * cornerRadius
            let endY = currentPoint.y + toNext.y / dist2 * cornerRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: startX, y: startY))
            } else {
                path.addLine(to: CGPoint(x: startX, y: startY))
            }
            
            // Добавляем дугу для скругления угла
            path.addQuadCurve(to: CGPoint(x: endX, y: endY), control: currentPoint)
        }
        path.closeSubpath()
        return path
    }
    
    private func drawRhombus(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Поворачиваем на 45° для ромба
        ctx.rotate(by: .pi / 4)
        
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let cornerRadius = size / 2.7
        
        // Внешнее кольцо
        let outerPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Внутреннее кольцо
        let innerInset: CGFloat = 8
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: max(cornerRadius - innerInset / 2, 0), cornerHeight: max(cornerRadius - innerInset / 2, 0), transform: nil)
        ctx.addPath(innerPath)
        ctx.setStrokeColor(base.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(innerLineWidth)
        ctx.strokePath()
    }
    
    // MARK: - Обработка кликов
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        onClick?()
    }
}
