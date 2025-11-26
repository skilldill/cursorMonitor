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
    
    // Анимируемые свойства для переходов
    private var animatedScale: CGFloat = 1.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    private var animatedColorProgress: CGFloat = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    // Таймер для анимации
    private var animationTimer: Timer?
    
    // Обработчик клика для разморозки курсора
    var onClick: (() -> Void)?
    // Обработчик отпускания кнопки мыши
    var onMouseUp: (() -> Void)?
    
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(innerGlowStyleChanged),
            name: .innerGlowStyleChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(outerLineWidthChanged),
            name: .outerLineWidthChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shadowColorChanged),
            name: .cursorShadowColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shadowColorChanged),
            name: .cursorColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shadowBrightnessChanged),
            name: .cursorShadowBrightnessChanged,
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
    
    @objc private func innerGlowStyleChanged() {
        needsDisplay = true
    }
    
    @objc private func outerLineWidthChanged() {
        needsDisplay = true
    }
    
    @objc private func shadowColorChanged() {
        needsDisplay = true
    }
    
    @objc private func shadowBrightnessChanged() {
        needsDisplay = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        animationTimer?.invalidate()
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

        // Интерполируем цвет между baseColor и clickColor на основе animatedColorProgress
        let interpolatedColor: NSColor
        if animatedColorProgress <= 0 {
            interpolatedColor = baseColor
        } else if animatedColorProgress >= 1 {
            interpolatedColor = clickColor
        } else {
            // Конвертируем цвета в RGB пространство для корректной интерполяции
            let baseRGB = baseColor.usingColorSpace(.deviceRGB) ?? baseColor
            let clickRGB = clickColor.usingColorSpace(.deviceRGB) ?? clickColor
            
            var baseR: CGFloat = 0, baseG: CGFloat = 0, baseB: CGFloat = 0, baseA: CGFloat = 0
            var clickR: CGFloat = 0, clickG: CGFloat = 0, clickB: CGFloat = 0, clickA: CGFloat = 0
            
            baseRGB.getRed(&baseR, green: &baseG, blue: &baseB, alpha: &baseA)
            clickRGB.getRed(&clickR, green: &clickG, blue: &clickB, alpha: &clickA)
            
            let r = baseR + (clickR - baseR) * animatedColorProgress
            let g = baseG + (clickG - baseG) * animatedColorProgress
            let b = baseB + (clickB - baseB) * animatedColorProgress
            let a = baseA + (clickA - baseA) * animatedColorProgress
            
            interpolatedColor = NSColor(deviceRed: r, green: g, blue: b, alpha: a)
        }
        
        let base = interpolatedColor.withAlphaComponent(opacity)

        // Параметры линий
        let outerLineWidth: CGFloat = CursorSettings.shared.outerLineWidth
        let innerLineWidth: CGFloat = 8

        // Немного отступим от краёв
        let inset: CGFloat = 12

        // Прямоугольник, в который впишем фигуру
        let rect = bounds.insetBy(dx: inset, dy: inset)
        // МАСШТАБИРУЕМ сам размер, а не слой (используем animatedScale для плавной анимации)
        let size = min(rect.width, rect.height) * animatedScale

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
        case .pentagon:
            drawPentagon(ctx: ctx, size: size, base: base, outerLineWidth: outerLineWidth, innerLineWidth: innerLineWidth)
        }

        ctx.restoreGState()
    }

    // MARK: - Клик

    /// Вызывается при mouseDown
    func beginClick() {
        isPulsing = true
        currentScale = 0.9   // чуть уменьшаем фигуру
        
        // Анимируем переход цвета и размера
        animateToScale(0.9, colorProgress: 1.0)
    }

    /// Вызывается при mouseUp
    func endClick() {
        isPulsing = false
        currentScale = 1.0   // возвращаем нормальный размер
        
        // Анимируем возврат цвета и размера
        animateToScale(1.0, colorProgress: 0.0)
    }
    
    /// Анимирует переход к указанному масштабу и прогрессу цвета
    private func animateToScale(_ targetScale: CGFloat, colorProgress: CGFloat) {
        // Останавливаем предыдущую анимацию, если она есть
        animationTimer?.invalidate()
        
        let startScale = animatedScale
        let startColorProgress = animatedColorProgress
        let duration: TimeInterval = 0.05
        let startTime = Date()
        
        // Используем таймер для плавной анимации
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Используем ease-in-out кривую
            let easedProgress = progress < 0.5
                ? 2 * progress * progress
                : 1 - pow(-2 * progress + 2, 2) / 2
            
            // Интерполируем значения
            self.animatedScale = startScale + (targetScale - startScale) * easedProgress
            self.animatedColorProgress = startColorProgress + (colorProgress - startColorProgress) * easedProgress
            
            if progress >= 1.0 {
                timer.invalidate()
                self.animationTimer = nil
                // Убеждаемся, что финальные значения установлены точно
                self.animatedScale = targetScale
                self.animatedColorProgress = colorProgress
            }
        }
        
        animationTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    // Старый "пульс" можно оставить на случай использования где-то ещё
    func pulse() {
        isPulsing = true
        currentScale = 0.9
        animateToScale(0.9, colorProgress: 1.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.isPulsing = false
            self?.currentScale = 1.0
            self?.animateToScale(1.0, colorProgress: 0.0)
        }
    }

    // На случай если что-то пошло не так
    private func simplePulseFallback() {
        isPulsing = true
        currentScale = 0.9
        animateToScale(0.9, colorProgress: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.isPulsing = false
            self?.currentScale = 1.0
            self?.animateToScale(1.0, colorProgress: 0.0)
        }
    }
    
    // MARK: - Отрисовка форм
    
    // Вспомогательная функция для рисования сегментированной линии используя dash pattern
    private func drawSegmentedStroke(ctx: CGContext, path: CGPath, color: NSColor, lineWidth: CGFloat, segmentLength: CGFloat = 8, gapLength: CGFloat = 4) {
        ctx.addPath(path)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineDash(phase: 0, lengths: [segmentLength, gapLength])
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: []) // Сбрасываем dash pattern
    }
    
    // Вспомогательная функция для рисования внутреннего кольца (сплошного или сегментированного)
    private func drawInnerRing(ctx: CGContext, path: CGPath, color: NSColor, lineWidth: CGFloat) {
        let style = CursorSettings.shared.innerGlowStyle
        switch style {
        case .segmented:
            // Сегментированная: тоньше чем было, но на 2 пикселя толще чем тонкая сегментация (1 + 2 = 3)
            drawSegmentedStroke(ctx: ctx, path: path, color: color, lineWidth: lineWidth, segmentLength: 3, gapLength: 2)
        case .thinSegmented:
            drawSegmentedStroke(ctx: ctx, path: path, color: color, lineWidth: lineWidth, segmentLength: 1, gapLength: 1)
        case .solid:
            ctx.addPath(path)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.strokePath()
        }
    }
    
    private func drawSquircle(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let cornerRadius = size / 3.5 // Сильно скругленные углы
        
        // Настраиваем тень для легкой подсветки внешнего контура
        let shadowBrightness = CursorSettings.shared.shadowBrightness
        if shadowBrightness > 0 {
            let shadowColor = CursorSettings.shared.effectiveShadowColor.color
            ctx.setShadow(
                offset: CGSize(width: 0, height: 0),
                blur: 15.0, // Радиус размытия для легкой подсветки
                color: shadowColor.withAlphaComponent(shadowBrightness).cgColor
            )
        }
        
        // Внешнее кольцо
        let outerPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Отключаем тень для внутреннего кольца
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Внутреннее кольцо
        let innerInset: CGFloat = 8
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: max(cornerRadius - innerInset / 2, 0), cornerHeight: max(cornerRadius - innerInset / 2, 0), transform: nil)
        drawInnerRing(ctx: ctx, path: innerPath, color: base.withAlphaComponent(0.35), lineWidth: innerLineWidth)
    }
    
    private func drawCircle(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Используем rounded rect с большим cornerRadius для более мягкого вида
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let cornerRadius = size / 2 // Максимальное скругление для круга
        
        // Настраиваем тень для легкой подсветки внешнего контура
        let shadowBrightness = CursorSettings.shared.shadowBrightness
        if shadowBrightness > 0 {
            let shadowColor = CursorSettings.shared.effectiveShadowColor.color
            ctx.setShadow(
                offset: CGSize(width: 0, height: 0),
                blur: 15.0, // Радиус размытия для легкой подсветки
                color: shadowColor.withAlphaComponent(shadowBrightness).cgColor
            )
        }
        
        // Внешнее кольцо
        let outerPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Отключаем тень для внутреннего кольца
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Внутреннее кольцо
        let innerInset: CGFloat = 8
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: max(cornerRadius - innerInset / 2, 0), cornerHeight: max(cornerRadius - innerInset / 2, 0), transform: nil)
        drawInnerRing(ctx: ctx, path: innerPath, color: base.withAlphaComponent(0.35), lineWidth: innerLineWidth)
    }
    
    private func drawHexagon(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Увеличиваем радиус для более длинных граней (примерно на 20%)
        let radius = size / 2 * 1.2
        let cornerRadius = size / 4.5 // Увеличенное скругление углов, пропорционально размеру
        
        // Настраиваем тень для легкой подсветки внешнего контура
        let shadowBrightness = CursorSettings.shared.shadowBrightness
        if shadowBrightness > 0 {
            let shadowColor = CursorSettings.shared.effectiveShadowColor.color
            ctx.setShadow(
                offset: CGSize(width: 0, height: 0),
                blur: 15.0, // Радиус размытия для легкой подсветки
                color: shadowColor.withAlphaComponent(shadowBrightness).cgColor
            )
        }
        
        // Внешний шестиугольник
        let outerPath = createRoundedHexagonPath(radius: radius, cornerRadius: cornerRadius)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Отключаем тень для внутреннего кольца
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Внутренний шестиугольник
        let innerInset: CGFloat = 8
        let innerRadius = radius - innerInset
        let innerPath = createRoundedHexagonPath(radius: innerRadius, cornerRadius: max(cornerRadius - innerInset / 2, 0))
        drawInnerRing(ctx: ctx, path: innerPath, color: base.withAlphaComponent(0.35), lineWidth: innerLineWidth)
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
        
        // Настраиваем тень для легкой подсветки внешнего контура
        let shadowBrightness = CursorSettings.shared.shadowBrightness
        if shadowBrightness > 0 {
            let shadowColor = CursorSettings.shared.effectiveShadowColor.color
            ctx.setShadow(
                offset: CGSize(width: 0, height: 0),
                blur: 15.0, // Радиус размытия для легкой подсветки
                color: shadowColor.withAlphaComponent(shadowBrightness).cgColor
            )
        }
        
        // Внешний треугольник
        let outerPath = createRoundedTrianglePath(radius: radius, cornerRadius: cornerRadius)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Отключаем тень для внутреннего кольца
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Внутренний треугольник
        let innerInset: CGFloat = 8
        let innerRadius = radius - innerInset
        let innerPath = createRoundedTrianglePath(radius: innerRadius, cornerRadius: max(cornerRadius - innerInset / 2, 0))
        drawInnerRing(ctx: ctx, path: innerPath, color: base.withAlphaComponent(0.35), lineWidth: innerLineWidth)
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
    
    private func drawPentagon(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Увеличиваем радиус для более длинных граней (примерно на 20%)
        let radius = size / 2 * 1.2
        let cornerRadius = size / 4.5 // Увеличенное скругление углов, пропорционально размеру
        
        // Настраиваем тень для легкой подсветки внешнего контура
        let shadowBrightness = CursorSettings.shared.shadowBrightness
        if shadowBrightness > 0 {
            let shadowColor = CursorSettings.shared.effectiveShadowColor.color
            ctx.setShadow(
                offset: CGSize(width: 0, height: 0),
                blur: 15.0, // Радиус размытия для легкой подсветки
                color: shadowColor.withAlphaComponent(shadowBrightness).cgColor
            )
        }
        
        // Внешний пятиугольник
        let outerPath = createRoundedPentagonPath(radius: radius, cornerRadius: cornerRadius)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Отключаем тень для внутреннего кольца
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Внутренний пятиугольник
        let innerInset: CGFloat = 8
        let innerRadius = radius - innerInset
        let innerPath = createRoundedPentagonPath(radius: innerRadius, cornerRadius: max(cornerRadius - innerInset / 2, 0))
        drawInnerRing(ctx: ctx, path: innerPath, color: base.withAlphaComponent(0.35), lineWidth: innerLineWidth)
    }
    
    private func createRoundedPentagonPath(radius: CGFloat, cornerRadius: CGFloat) -> CGMutablePath {
        let path = CGMutablePath()
        let sides = 5
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
    
    private func drawRhombus(ctx: CGContext, size: CGFloat, base: NSColor, outerLineWidth: CGFloat, innerLineWidth: CGFloat) {
        // Поворачиваем на 45° для ромба
        ctx.rotate(by: .pi / 4)
        
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let cornerRadius = size / 2.7
        
        // Настраиваем тень для легкой подсветки внешнего контура
        let shadowBrightness = CursorSettings.shared.shadowBrightness
        if shadowBrightness > 0 {
            let shadowColor = CursorSettings.shared.effectiveShadowColor.color
            ctx.setShadow(
                offset: CGSize(width: 0, height: 0),
                blur: 15.0, // Радиус размытия для легкой подсветки
                color: shadowColor.withAlphaComponent(shadowBrightness).cgColor
            )
        }
        
        // Внешнее кольцо
        let outerPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()
        
        // Отключаем тень для внутреннего кольца
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        // Внутреннее кольцо
        let innerInset: CGFloat = 8
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: max(cornerRadius - innerInset / 2, 0), cornerHeight: max(cornerRadius - innerInset / 2, 0), transform: nil)
        drawInnerRing(ctx: ctx, path: innerPath, color: base.withAlphaComponent(0.35), lineWidth: innerLineWidth)
    }
    
    // MARK: - Обработка кликов
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        onClick?()
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        onMouseUp?()
    }
}
