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
        // МАСШТАБИРУЕМ сам квадрат, а не слой
        let size = min(rect.width, rect.height) * currentScale

        // Включаем свечение
//        ctx.setShadow(offset: .zero,
//                      blur: 12,
//                      color: base.withAlphaComponent(0.7).cgColor)

        // Координатная система: центр в середине view + поворот на 45°
        ctx.saveGState()
        ctx.translateBy(x: bounds.midX, y: bounds.midY)
        ctx.rotate(by: .pi / 4)

        // Квадрат с центром в (0,0)
        let squareRect = CGRect(x: -size / 2, y: -size / 2,
                                width: size, height: size)
        let cornerRadius = size / 2.7   // можно поиграть этим значением

        // ==== ВНЕШНЕЕ КОЛЬЦО ====
        let outerPath = CGPath(roundedRect: squareRect,
                               cornerWidth: cornerRadius,
                               cornerHeight: cornerRadius,
                               transform: nil)

        ctx.addPath(outerPath)
        ctx.setStrokeColor(base.cgColor)
        ctx.setLineWidth(outerLineWidth)
        ctx.strokePath()

        // ==== ВНУТРЕННЕЕ КОЛЬЦО ====
        let innerInset: CGFloat = 8   // расстояние между кольцами
        let innerRect = squareRect.insetBy(dx: innerInset, dy: innerInset)

        let innerPath = CGPath(roundedRect: innerRect,
                               cornerWidth: max(cornerRadius - innerInset / 2, 0),
                               cornerHeight: max(cornerRadius - innerInset / 2, 0),
                               transform: nil)

        ctx.addPath(innerPath)
        ctx.setStrokeColor(base.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(innerLineWidth)
        ctx.strokePath()

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
    
    // MARK: - Обработка кликов
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        onClick?()
    }
}
