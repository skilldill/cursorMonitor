import Cocoa

class PencilSettingsPanel: NSView {
    private var colorButtons: [NSButton] = []
    private var thicknessSlider: NSSlider?
    private var opacitySlider: NSSlider?
    private var thicknessLabel: NSTextField?
    private var opacityLabel: NSTextField?
    private var glowCheckbox: NSButton?
    
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
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        
        setupUI()
        setupNotifications()
    }
    
    private func setupNotifications() {
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
            selector: #selector(pencilOpacityChanged),
            name: .pencilOpacityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pencilGlowEnabledChanged),
            name: .pencilGlowEnabledChanged,
            object: nil
        )
    }
    
    @objc private func pencilColorChanged() {
        updateColorButtons()
    }
    
    @objc private func pencilLineWidthChanged() {
        thicknessSlider?.doubleValue = CursorSettings.shared.pencilLineWidth
        updateThicknessLabel()
    }
    
    @objc private func pencilOpacityChanged() {
        opacitySlider?.doubleValue = CursorSettings.shared.pencilOpacity
        updateOpacityLabel()
    }
    
    @objc private func pencilGlowEnabledChanged() {
        glowCheckbox?.state = CursorSettings.shared.pencilGlowEnabled ? .on : .off
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        // Отступы
        let padding: CGFloat = 16
        let spacing: CGFloat = 12
        let buttonSize: CGFloat = 24
        let buttonSpacing: CGFloat = 8
        
        var currentY = frame.height - padding
        
        // Заголовок
        let titleLabel = NSTextField(labelWithString: "Настройки карандаша")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: padding, y: currentY - 18, width: frame.width - padding * 2, height: 18)
        addSubview(titleLabel)
        
        currentY -= 30
        
        // Цвет
        let colorLabel = NSTextField(labelWithString: "Цвет:")
        colorLabel.font = NSFont.systemFont(ofSize: 12)
        colorLabel.textColor = .secondaryLabelColor
        colorLabel.frame = NSRect(x: padding, y: currentY - 16, width: 60, height: 16)
        addSubview(colorLabel)
        
        // Кнопки выбора цвета
        let colors = CursorColor.allCases
        let colorsPerRow = 5
        let totalRows = (colors.count + colorsPerRow - 1) / colorsPerRow
        let colorButtonsHeight = CGFloat(totalRows) * (buttonSize + buttonSpacing) - buttonSpacing
        
        var buttonX = padding + 60
        var buttonY = currentY - buttonSize
        var currentRow = 0
        var currentCol = 0
        
        for (index, color) in colors.enumerated() {
            let button = NSButton()
            button.setButtonType(.momentaryPushIn)
            button.isBordered = false
            button.title = ""
            button.wantsLayer = true
            button.layer?.cornerRadius = buttonSize / 2
            button.layer?.backgroundColor = color.color.cgColor
            button.layer?.borderWidth = 2
            button.layer?.borderColor = NSColor.separatorColor.cgColor
            
            let x = buttonX + CGFloat(currentCol) * (buttonSize + buttonSpacing)
            let y = buttonY - CGFloat(currentRow) * (buttonSize + buttonSpacing)
            button.frame = NSRect(x: x, y: y, width: buttonSize, height: buttonSize)
            
            button.target = self
            button.action = #selector(colorButtonClicked(_:))
            button.tag = index
            
            addSubview(button)
            colorButtons.append(button)
            
            currentCol += 1
            if currentCol >= colorsPerRow {
                currentCol = 0
                currentRow += 1
            }
        }
        
        currentY -= colorButtonsHeight + spacing
        
        // Толщина
        let thicknessLabel = NSTextField(labelWithString: "Толщина:")
        thicknessLabel.font = NSFont.systemFont(ofSize: 12)
        thicknessLabel.textColor = .secondaryLabelColor
        thicknessLabel.frame = NSRect(x: padding, y: currentY - 16, width: 80, height: 16)
        addSubview(thicknessLabel)
        
        let thicknessValueLabel = NSTextField(labelWithString: "")
        thicknessValueLabel.font = NSFont.systemFont(ofSize: 11)
        thicknessValueLabel.textColor = .secondaryLabelColor
        thicknessValueLabel.alignment = .right
        thicknessValueLabel.frame = NSRect(x: frame.width - padding - 50, y: currentY - 16, width: 50, height: 16)
        addSubview(thicknessValueLabel)
        self.thicknessLabel = thicknessValueLabel
        
        currentY -= 20
        
        let thicknessSlider = NSSlider(value: CursorSettings.shared.pencilLineWidth,
                                      minValue: 1.0,
                                      maxValue: 20.0,
                                      target: self,
                                      action: #selector(thicknessSliderChanged(_:)))
        thicknessSlider.frame = NSRect(x: padding, y: currentY - 20, width: frame.width - padding * 2, height: 20)
        addSubview(thicknessSlider)
        self.thicknessSlider = thicknessSlider
        
        updateThicknessLabel()
        
        currentY -= 30
        
        // Прозрачность
        let opacityLabel = NSTextField(labelWithString: "Прозрачность:")
        opacityLabel.font = NSFont.systemFont(ofSize: 12)
        opacityLabel.textColor = .secondaryLabelColor
        opacityLabel.frame = NSRect(x: padding, y: currentY - 16, width: 100, height: 16)
        addSubview(opacityLabel)
        
        let opacityValueLabel = NSTextField(labelWithString: "")
        opacityValueLabel.font = NSFont.systemFont(ofSize: 11)
        opacityValueLabel.textColor = .secondaryLabelColor
        opacityValueLabel.alignment = .right
        opacityValueLabel.frame = NSRect(x: frame.width - padding - 50, y: currentY - 16, width: 50, height: 16)
        addSubview(opacityValueLabel)
        self.opacityLabel = opacityValueLabel
        
        currentY -= 20
        
        let opacitySlider = NSSlider(value: CursorSettings.shared.pencilOpacity,
                                    minValue: 0.1,
                                    maxValue: 1.0,
                                    target: self,
                                    action: #selector(opacitySliderChanged(_:)))
        opacitySlider.frame = NSRect(x: padding, y: currentY - 20, width: frame.width - padding * 2, height: 20)
        addSubview(opacitySlider)
        self.opacitySlider = opacitySlider
        
        updateOpacityLabel()
        
        currentY -= 30
        
        // Светящиеся линии
        let glowCheckbox = NSButton(checkboxWithTitle: "Светящиеся линии", target: self, action: #selector(glowCheckboxChanged(_:)))
        glowCheckbox.state = CursorSettings.shared.pencilGlowEnabled ? .on : .off
        glowCheckbox.font = NSFont.systemFont(ofSize: 12)
        glowCheckbox.frame = NSRect(x: padding, y: currentY - 20, width: frame.width - padding * 2, height: 20)
        addSubview(glowCheckbox)
        self.glowCheckbox = glowCheckbox
        
        updateColorButtons()
    }
    
    @objc private func colorButtonClicked(_ sender: NSButton) {
        let colors = CursorColor.allCases
        guard sender.tag < colors.count else { return }
        CursorSettings.shared.pencilColor = colors[sender.tag]
    }
    
    @objc private func thicknessSliderChanged(_ sender: NSSlider) {
        CursorSettings.shared.pencilLineWidth = sender.doubleValue
        updateThicknessLabel()
    }
    
    @objc private func opacitySliderChanged(_ sender: NSSlider) {
        CursorSettings.shared.pencilOpacity = sender.doubleValue
        updateOpacityLabel()
    }
    
    @objc private func glowCheckboxChanged(_ sender: NSButton) {
        CursorSettings.shared.pencilGlowEnabled = (sender.state == .on)
    }
    
    private func updateColorButtons() {
        let currentColor = CursorSettings.shared.pencilColor
        let colors = CursorColor.allCases
        
        for (index, button) in colorButtons.enumerated() {
            if index < colors.count {
                let color = colors[index]
                if color == currentColor {
                    button.layer?.borderWidth = 3
                    button.layer?.borderColor = NSColor.controlAccentColor.cgColor
                } else {
                    button.layer?.borderWidth = 2
                    button.layer?.borderColor = NSColor.separatorColor.cgColor
                }
            }
        }
    }
    
    private func updateThicknessLabel() {
        let value = CursorSettings.shared.pencilLineWidth
        thicknessLabel?.stringValue = String(format: "%.1f", value)
    }
    
    private func updateOpacityLabel() {
        let value = CursorSettings.shared.pencilOpacity
        opacityLabel?.stringValue = String(format: "%.0f%%", value * 100)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Рисуем фон с тенью
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: 8, color: NSColor.black.withAlphaComponent(0.2).cgColor)
        
        let backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        backgroundColor.setFill()
        
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        path.fill()
        
        context.restoreGState()
    }
}

