import Cocoa

final class HighlightView: NSView {

    // Базовый цвет подсветки
    private let baseColor = NSColor.systemBlue
    // Цвет при клике
    private let clickColor = NSColor.systemPink

    // Текущее состояние
    private var isPulsing = false

    // Коэффициент масштаба фигуры (1.0 — полный размер)
    private var currentScale: CGFloat = 1.0 {
        didSet {
            needsDisplay = true
        }
    }

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
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.clear(bounds)

        let base = (isPulsing ? clickColor : baseColor).withAlphaComponent(0.9)

        // Параметры линий
        let outerLineWidth: CGFloat = 6
        let innerLineWidth: CGFloat = 10

        // Немного отступим от краёв
        let inset: CGFloat = 12

        // Прямоугольник, в который впишем фигуру
        let rect = bounds.insetBy(dx: inset, dy: inset)
        // МАСШТАБИРУЕМ сам квадрат, а не слой
        let size = min(rect.width, rect.height) * currentScale

        // Включаем свечение
        ctx.setShadow(offset: .zero,
                      blur: 12,
                      color: base.withAlphaComponent(0.7).cgColor)

        // Координатная система: центр в середине view + поворот на 45°
        ctx.saveGState()
        ctx.translateBy(x: bounds.midX, y: bounds.midY)
        ctx.rotate(by: .pi / 4)

        // Квадрат с центром в (0,0)
        let squareRect = CGRect(x: -size / 2, y: -size / 2,
                                width: size, height: size)
        let cornerRadius = size / 3   // можно поиграть этим значением

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
        let innerInset: CGFloat = 14   // расстояние между кольцами
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
}
