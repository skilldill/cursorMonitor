import Cocoa

final class MenuView: NSView {
    
    // Обработчики кликов
    var onSafariClick: (() -> Void)?
    var onViewNotesClick: (() -> Void)?
    var onCalculatorClick: (() -> Void)?
    var onCreateNote: (() -> Void)?
    var onClose: (() -> Void)?
    
    private var safariButton: NSButton?
    private var viewNotesButton: NSButton?
    private var calculatorButton: NSButton?
    private var createNoteButton: NSButton?
    private var closeButton: NSButton?
    
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
        layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.95).cgColor
        layer?.cornerRadius = 12
        
        setupButtons()
    }
    
    private func setupButtons() {
        let buttonHeight: CGFloat = 32
        let buttonSpacing: CGFloat = 8
        let padding: CGFloat = 12
        
        let buttonWidth = bounds.width - padding * 2
        var currentY = bounds.height - padding - buttonHeight
        
        // Кнопка создания заметки
        createNoteButton = createButton(
            title: "Создать заметку",
            frame: NSRect(x: padding, y: currentY, width: buttonWidth, height: buttonHeight),
            action: #selector(createNoteButtonClicked)
        )
        addSubview(createNoteButton!)
        
        currentY -= buttonHeight + buttonSpacing
        
        // Кнопка Safari
        safariButton = createButton(
            title: "Открыть браузер Safari",
            frame: NSRect(x: padding, y: currentY, width: buttonWidth, height: buttonHeight),
            action: #selector(safariButtonClicked)
        )
        addSubview(safariButton!)
        
        currentY -= buttonHeight + buttonSpacing
        
        // Кнопка просмотра заметок
        viewNotesButton = createButton(
            title: "Посмотреть заметки",
            frame: NSRect(x: padding, y: currentY, width: buttonWidth, height: buttonHeight),
            action: #selector(viewNotesButtonClicked)
        )
        addSubview(viewNotesButton!)
        
        currentY -= buttonHeight + buttonSpacing
        
        // Кнопка Calculator
        calculatorButton = createButton(
            title: "Калькулятор",
            frame: NSRect(x: padding, y: currentY, width: buttonWidth, height: buttonHeight),
            action: #selector(calculatorButtonClicked)
        )
        addSubview(calculatorButton!)
        
        currentY -= buttonHeight + buttonSpacing
        
        // Кнопка закрытия
        closeButton = createButton(
            title: "Закрыть",
            frame: NSRect(x: padding, y: currentY, width: buttonWidth, height: buttonHeight),
            action: #selector(closeButtonClicked)
        )
        addSubview(closeButton!)
    }
    
    private func createButton(title: String, frame: NSRect, action: Selector) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.bezelStyle = .rounded
        button.target = self
        button.action = action
        button.font = NSFont.systemFont(ofSize: 13)
        
        // Стилизация кнопки
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor(white: 0.2, alpha: 1.0).cgColor
        button.layer?.cornerRadius = 6
        
        // Цвет текста
        let attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 13)
            ]
        )
        button.attributedTitle = attributedTitle
        
        return button
    }
    
    @objc private func safariButtonClicked() {
        onSafariClick?()
    }
    
    @objc private func viewNotesButtonClicked() {
        onViewNotesClick?()
    }
    
    @objc private func calculatorButtonClicked() {
        onCalculatorClick?()
    }
    
    @objc private func createNoteButtonClicked() {
        onCreateNote?()
    }
    
    @objc private func closeButtonClicked() {
        onClose?()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Рисуем фон с закругленными углами
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(white: 0.1, alpha: 0.95).setFill()
        path.fill()
    }
}

