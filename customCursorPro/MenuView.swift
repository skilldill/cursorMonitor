import Cocoa

final class MenuView: NSView {
    
    // Обработчики кликов
    var onViewNotesClick: (() -> Void)?
    var onCalculatorClick: (() -> Void)?
    var onCreateNote: (() -> Void)?
    var onPencilClick: (() -> Void)?
    var onClose: (() -> Void)?
    
    private var viewNotesButton: NSButton?
    private var calculatorButton: NSButton?
    private var createNoteButton: NSButton?
    private var pencilButton: NSButton?
    private var closeButton: NSButton?
    
    private var visualEffectView: NSVisualEffectView?
    
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
        
        // Создаем NSVisualEffectView для blur эффекта
        let effectView = NSVisualEffectView(frame: bounds)
        effectView.material = .hudWindow // Современный материал с blur
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.masksToBounds = true
        
        // Добавляем легкую тень
        effectView.shadow = NSShadow()
        effectView.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.3)
        effectView.shadow?.shadowOffset = NSSize(width: 0, height: -2)
        effectView.shadow?.shadowBlurRadius = 10
        
        addSubview(effectView)
        visualEffectView = effectView
        
        layer?.cornerRadius = 16
        
        setupButtons()
        applyTheme()
        
        // Подписываемся на изменения темы
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: .menuThemeChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func themeChanged() {
        applyTheme()
    }
    
    private func applyTheme() {
        let theme = CursorSettings.shared.menuTheme
        
        switch theme {
        case .dark:
            // Тёмная тема
            visualEffectView?.material = .hudWindow
            visualEffectView?.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.3)
            layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.1).cgColor
            
            // Обновляем кнопки для тёмной темы
            updateButtonsTheme(isDark: true)
            
        case .light:
            // Светлая тема
            visualEffectView?.material = .light
            visualEffectView?.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.15)
            layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.05).cgColor
            
            // Обновляем кнопки для светлой темы
            updateButtonsTheme(isDark: false)
        }
        
        needsDisplay = true
    }
    
    private func updateButtonsTheme(isDark: Bool) {
        let buttons = [createNoteButton, viewNotesButton, calculatorButton, pencilButton, closeButton].compactMap { $0 }
        
        for button in buttons {
            if let hoverButton = button as? HoverButton {
                hoverButton.isDarkTheme = isDark
                hoverButton.updateTheme()
            }
            // Обновляем цвет иконок
            button.contentTintColor = isDark ? .labelColor : NSColor(white: 0.1, alpha: 1.0)
        }
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        visualEffectView?.frame = bounds
    }
    
    private func setupButtons() {
        let buttonSize: CGFloat = 48
        let buttonSpacing: CGFloat = 12
        let padding: CGFloat = 16
        
        // Горизонтальная раскладка (flex)
        let buttonConfigs: [(icon: String, action: Selector)] = [
            ("square.and.pencil", #selector(createNoteButtonClicked)),
            ("note.text", #selector(viewNotesButtonClicked)),
            ("function", #selector(calculatorButtonClicked)),
            ("pencil.tip", #selector(pencilButtonClicked)),
            ("xmark.circle.fill", #selector(closeButtonClicked))
        ]
        
        let totalWidth = CGFloat(buttonConfigs.count) * buttonSize + CGFloat(buttonConfigs.count - 1) * buttonSpacing + padding * 2
        let startX = (bounds.width - totalWidth) / 2 + padding
        let centerY = bounds.midY - buttonSize / 2
        
        var currentX = startX
        
        for (index, config) in buttonConfigs.enumerated() {
            let button = createIconButton(
                iconName: config.icon,
                frame: NSRect(x: currentX, y: centerY, width: buttonSize, height: buttonSize),
                action: config.action
            )
            addSubview(button)
            
            // Присваиваем кнопку соответствующему свойству по индексу
            switch index {
            case 0:
                createNoteButton = button
            case 1:
                viewNotesButton = button
            case 2:
                calculatorButton = button
            case 3:
                pencilButton = button
            case 4:
                closeButton = button
            default:
                break
            }
            
            currentX += buttonSize + buttonSpacing
        }
    }
    
    private func createIconButton(iconName: String, frame: NSRect, action: Selector) -> NSButton {
        let button = HoverButton(frame: frame)
        button.title = ""
        button.target = self
        button.action = action
        button.bezelStyle = .texturedSquare
        button.isBordered = false
        
        // Устанавливаем тему кнопки
        button.isDarkTheme = CursorSettings.shared.menuTheme == .dark
        
        // Стилизация кнопки в стиле Tailwind
        button.wantsLayer = true
        button.layer?.cornerRadius = frame.width / 2 // Круглая кнопка
        
        // Иконка SF Symbols
        if let iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            iconImage.isTemplate = true
            iconImage.size = NSSize(width: 24, height: 24)
            button.image = iconImage
            button.imagePosition = .imageOnly
            // Устанавливаем контрастный цвет для светлой темы
            let isDark = CursorSettings.shared.menuTheme == .dark
            button.contentTintColor = isDark ? .labelColor : NSColor(white: 0.1, alpha: 1.0)
        }
        
        button.updateTheme()
        
        return button
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Рисование теперь обрабатывается через NSVisualEffectView
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
    
    @objc private func pencilButtonClicked() {
        onPencilClick?()
    }
    
    @objc private func closeButtonClicked() {
        onClose?()
    }
}

// Кастомный класс кнопки с hover эффектом
class HoverButton: NSButton {
    private var hoverView: NSView?
    var isDarkTheme: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupHover()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupHover()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHover()
    }
    
    func updateTheme() {
        if isDarkTheme {
            layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.1).cgColor
        } else {
            layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.1).cgColor
        }
        needsDisplay = true
    }
    
    private func setupHover() {
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        
        hoverView = NSView(frame: bounds)
        hoverView?.wantsLayer = true
        hoverView?.layer?.cornerRadius = bounds.width / 2 // Круглая для круглых кнопок
        hoverView?.layer?.backgroundColor = NSColor.clear.cgColor
        hoverView?.isHidden = true
        addSubview(hoverView!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            hoverView?.isHidden = false
            if isDarkTheme {
                hoverView?.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.15).cgColor
                layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.2).cgColor
            } else {
                hoverView?.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.15).cgColor
                layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.2).cgColor
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            hoverView?.isHidden = true
            hoverView?.layer?.backgroundColor = NSColor.clear.cgColor
            if isDarkTheme {
                layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.1).cgColor
            } else {
                layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.1).cgColor
            }
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        let newTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(newTrackingArea)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        hoverView?.frame = bounds
    }
}

