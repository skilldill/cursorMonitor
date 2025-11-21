import Cocoa

class SettingsWindow: NSWindowController {
    
    private var colorPopUp: NSPopUpButton!
    private var sizePopUp: NSPopUpButton!
    private var shapePopUp: NSPopUpButton!
    private var innerGlowStylePopUp: NSPopUpButton!
    private var outerLineWidthSlider: NSSlider!
    private var outerLineWidthLabel: NSTextField!
    private var opacitySlider: NSSlider!
    private var opacityLabel: NSTextField!
    private var clickColorPopUp: NSPopUpButton!
    private var pencilColorPopUp: NSPopUpButton!
    private var pencilLineWidthSlider: NSSlider!
    private var pencilLineWidthLabel: NSTextField!
    private var pencilOpacitySlider: NSSlider!
    private var pencilOpacityLabel: NSTextField!
    private var shadowBrightnessSlider: NSSlider!
    private var shadowBrightnessLabel: NSTextField!
    private var previewView: HighlightView!
    private var highlighter: CursorHighlighter?
    
    // Контейнеры
    private var appearanceContainer: NSView!
    private var contentContainer: NSView!
    private var visualEffectView: NSVisualEffectView!
    private var themeSwitch: NSSwitch!
    
    override init(window: NSWindow?) {
        super.init(window: window)
        createWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createWindow()
    }
    
    convenience init() {
        self.init(window: nil)
    }
    
    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 800),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cursor Pro Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Создаем основной контейнер с блюром
        let contentView = window.contentView!
        contentView.wantsLayer = true
        
        // NSVisualEffectView для стеклянного блюра
        visualEffectView = NSVisualEffectView(frame: contentView.bounds)
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.autoresizingMask = [.width, .height]
        contentView.addSubview(visualEffectView)
        
        // Контейнер для контента
        contentContainer = NSView(frame: contentView.bounds)
        contentContainer.wantsLayer = true
        contentContainer.autoresizingMask = [.width, .height]
        contentView.addSubview(contentContainer)
        
        // Подписываемся на изменения темы
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: .appThemeChanged,
            object: nil
        )
        
        // Область превью
        setupPreview()
        
        // Контейнер для настроек Appearance
        appearanceContainer = NSView()
        setupAppearanceSettings()
        
        // Применяем тему после создания всех элементов
        applyTheme()
        
        // Устанавливаем делегат для обработки закрытия окна
        window.delegate = self
        
        // Обновляем превью при изменении настроек
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorSizeChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorShapeChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorOpacityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .innerGlowStyleChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .outerLineWidthChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorClickColorChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorShadowBrightnessChanged,
            object: nil
        )
        
        self.window = window
    }
    
    @objc private func themeChanged() {
        applyTheme()
    }
    
    private func applyTheme() {
        guard let visualEffectView = visualEffectView else { return }
        let theme = CursorSettings.shared.menuTheme
        
        switch theme {
        case .dark:
            visualEffectView.material = .hudWindow
        case .light:
            visualEffectView.material = .light
        }
        
        // Обновляем цвета текста и элементов
        updateControlsTheme()
    }
    
    private func updateControlsTheme() {
        let isDark = CursorSettings.shared.menuTheme == .dark
        
        // Цвет текста: для светлой темы используем темный контрастный цвет
        let textColor = isDark ? NSColor.labelColor : NSColor(white: 0.1, alpha: 1.0)
        
        // Обновляем цвета всех текстовых меток в contentContainer
        for subview in contentContainer.subviews {
            if let label = subview as? NSTextField, label.isEditable == false {
                label.textColor = textColor
            }
            // Также обновляем метки внутри вложенных контейнеров (например, previewContainer)
            if let container = subview as? NSView {
                for nestedSubview in container.subviews {
                    if let label = nestedSubview as? NSTextField, label.isEditable == false {
                        label.textColor = textColor
                    }
                }
            }
        }
        
        // Обновляем switch темы
        if let themeSwitch = themeSwitch {
            themeSwitch.state = isDark ? .off : .on
        }
        
        // Обновляем метку рядом со switch
        for subview in contentContainer.subviews {
            if let label = subview as? NSTextField, label.tag == 999 {
                label.stringValue = isDark ? "Dark" : "Light"
                label.textColor = textColor
                break
            }
        }
    }
    
    private func setupPreview() {
        let windowHeight: CGFloat = 800
        let windowWidth: CGFloat = 600
        let previewContainer = NSView(frame: NSRect(x: 20, y: windowHeight - 220, width: windowWidth - 40, height: 200))
        previewContainer.wantsLayer = true
        previewContainer.layer?.cornerRadius = 12
        previewContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
        previewContainer.autoresizingMask = [.width, .minYMargin]
        contentContainer.addSubview(previewContainer)
        
        // Заголовок превью
        let previewLabel = NSTextField(labelWithString: "Preview")
        previewLabel.frame = NSRect(x: 20, y: previewContainer.bounds.height - 30, width: 100, height: 20)
        previewLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        // Устанавливаем цвет в зависимости от темы
        let isDark = CursorSettings.shared.menuTheme == .dark
        previewLabel.textColor = isDark ? .labelColor : NSColor(white: 0.1, alpha: 1.0)
        previewContainer.addSubview(previewLabel)
        
        // Превью курсора - используем точный размер как у реального курсора
        let previewDiameter = CursorSettings.shared.size.diameter
        let previewFrame = NSRect(
            x: previewContainer.bounds.midX - previewDiameter / 2,
            y: previewContainer.bounds.midY - previewDiameter / 2 - 10,
            width: previewDiameter,
            height: previewDiameter
        )
        previewView = HighlightView(frame: previewFrame)
        previewView.wantsLayer = true
        previewView.baseColor = CursorSettings.shared.color.color
        previewView.clickColor = CursorSettings.shared.clickColor.color
        previewView.opacity = CursorSettings.shared.opacity
        
        // Добавляем обработчики клика для превью
        previewView.onClick = { [weak self] in
            guard let self = self, let previewView = self.previewView else { return }
            // Показываем состояние клика при нажатии
            previewView.beginClick()
        }
        
        previewView.onMouseUp = { [weak self] in
            guard let self = self, let previewView = self.previewView else { return }
            // Возвращаем в обычное состояние при отпускании кнопки
            previewView.endClick()
        }
        
        previewContainer.addSubview(previewView)
    }
    
    private func setupAppearanceSettings() {
        let settingsY: CGFloat = 550
        let labelWidth: CGFloat = 180
        let controlX: CGFloat = 220
        let controlWidth: CGFloat = 320
        let rowHeight: CGFloat = 35
        var currentY = settingsY
        
        // Cursor Settings Section
        let cursorSectionLabel = createSectionLabel("Cursor Settings", y: currentY)
        contentContainer.addSubview(cursorSectionLabel)
        currentY -= 25
        
        // Цвет курсора
        let colorLabel = createLabel("Cursor Color:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(colorLabel)
        
        colorPopUp = createPopUpButton(frame: NSRect(x: controlX, y: currentY - 3, width: controlWidth, height: 26))
        setupColorMenu()
        colorPopUp.target = self
        colorPopUp.action = #selector(colorChanged)
        contentContainer.addSubview(colorPopUp)
        currentY -= rowHeight
        
        // Цвет при клике
        let clickColorLabel = createLabel("Click Color:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(clickColorLabel)
        
        clickColorPopUp = createPopUpButton(frame: NSRect(x: controlX, y: currentY - 3, width: controlWidth, height: 26))
        setupClickColorMenu()
        clickColorPopUp.target = self
        clickColorPopUp.action = #selector(clickColorChanged)
        contentContainer.addSubview(clickColorPopUp)
        currentY -= rowHeight
        
        // Размер курсора
        let sizeLabel = createLabel("Cursor Size:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(sizeLabel)
        
        sizePopUp = createPopUpButton(frame: NSRect(x: controlX, y: currentY - 3, width: controlWidth, height: 26))
        setupSizeMenu()
        sizePopUp.target = self
        sizePopUp.action = #selector(sizeChanged)
        contentContainer.addSubview(sizePopUp)
        currentY -= rowHeight
        
        // Форма курсора
        let shapeLabel = createLabel("Cursor Shape:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(shapeLabel)
        
        shapePopUp = createPopUpButton(frame: NSRect(x: controlX, y: currentY - 3, width: controlWidth, height: 26))
        setupShapeMenu()
        shapePopUp.target = self
        shapePopUp.action = #selector(shapeChanged)
        contentContainer.addSubview(shapePopUp)
        currentY -= rowHeight
        
        // Тип внутренней подсветки
        let innerGlowStyleLabel = createLabel("Inner Glow Style:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(innerGlowStyleLabel)
        
        innerGlowStylePopUp = createPopUpButton(frame: NSRect(x: controlX, y: currentY - 3, width: controlWidth, height: 26))
        setupInnerGlowStyleMenu()
        innerGlowStylePopUp.target = self
        innerGlowStylePopUp.action = #selector(innerGlowStyleChanged)
        contentContainer.addSubview(innerGlowStylePopUp)
        currentY -= rowHeight
        
        // Толщина внешней линии
        let outerLineWidthTitleLabel = createLabel("Outer Line Width:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(outerLineWidthTitleLabel)
        
        outerLineWidthSlider = createSlider(frame: NSRect(x: controlX, y: currentY, width: 250, height: 20))
        outerLineWidthSlider.minValue = 1.0
        outerLineWidthSlider.maxValue = 10.0
        outerLineWidthSlider.doubleValue = Double(CursorSettings.shared.outerLineWidth)
        outerLineWidthSlider.target = self
        outerLineWidthSlider.action = #selector(outerLineWidthChanged)
        contentContainer.addSubview(outerLineWidthSlider)
        
        outerLineWidthLabel = createLabel(String(format: "%.1f", CursorSettings.shared.outerLineWidth), frame: NSRect(x: controlX + 260, y: currentY, width: 60, height: 20))
        contentContainer.addSubview(outerLineWidthLabel)
        currentY -= rowHeight
        
        // Прозрачность
        let opacityTitleLabel = createLabel("Transparency:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(opacityTitleLabel)
        
        opacitySlider = createSlider(frame: NSRect(x: controlX, y: currentY, width: 250, height: 20))
        opacitySlider.minValue = 0.1
        opacitySlider.maxValue = 1.0
        opacitySlider.doubleValue = Double(CursorSettings.shared.opacity)
        opacitySlider.target = self
        opacitySlider.action = #selector(opacityChanged)
        contentContainer.addSubview(opacitySlider)
        
        opacityLabel = createLabel("\(Int(CursorSettings.shared.opacity * 100))%", frame: NSRect(x: controlX + 260, y: currentY, width: 60, height: 20))
        contentContainer.addSubview(opacityLabel)
        currentY -= rowHeight
        
        // Яркость тени
        let shadowBrightnessTitleLabel = createLabel("Shadow Brightness:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(shadowBrightnessTitleLabel)
        
        shadowBrightnessSlider = createSlider(frame: NSRect(x: controlX, y: currentY, width: 250, height: 20))
        shadowBrightnessSlider.minValue = 0.0
        shadowBrightnessSlider.maxValue = 1.0
        shadowBrightnessSlider.doubleValue = Double(CursorSettings.shared.shadowBrightness)
        shadowBrightnessSlider.target = self
        shadowBrightnessSlider.action = #selector(shadowBrightnessChanged)
        contentContainer.addSubview(shadowBrightnessSlider)
        
        shadowBrightnessLabel = createLabel("\(Int(CursorSettings.shared.shadowBrightness * 100))%", frame: NSRect(x: controlX + 260, y: currentY, width: 60, height: 20))
        contentContainer.addSubview(shadowBrightnessLabel)
        currentY -= rowHeight + 5
        
        // Pencil Settings Section
        let pencilSectionLabel = createSectionLabel("Pencil Settings", y: currentY)
        contentContainer.addSubview(pencilSectionLabel)
        currentY -= 25
        
        // Цвет карандаша
        let pencilColorLabel = createLabel("Pencil Color:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(pencilColorLabel)
        
        pencilColorPopUp = createPopUpButton(frame: NSRect(x: controlX, y: currentY - 3, width: controlWidth, height: 26))
        setupPencilColorMenu()
        pencilColorPopUp.target = self
        pencilColorPopUp.action = #selector(pencilColorChanged)
        contentContainer.addSubview(pencilColorPopUp)
        currentY -= rowHeight
        
        // Толщина линии карандаша
        let pencilLineWidthTitleLabel = createLabel("Line Thickness:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(pencilLineWidthTitleLabel)
        
        pencilLineWidthSlider = createSlider(frame: NSRect(x: controlX, y: currentY, width: 250, height: 20))
        pencilLineWidthSlider.minValue = 1.0
        pencilLineWidthSlider.maxValue = 20.0
        pencilLineWidthSlider.doubleValue = Double(CursorSettings.shared.pencilLineWidth)
        pencilLineWidthSlider.target = self
        pencilLineWidthSlider.action = #selector(pencilLineWidthChanged)
        contentContainer.addSubview(pencilLineWidthSlider)
        
        pencilLineWidthLabel = createLabel(String(format: "%.1f", CursorSettings.shared.pencilLineWidth), frame: NSRect(x: controlX + 260, y: currentY, width: 60, height: 20))
        contentContainer.addSubview(pencilLineWidthLabel)
        currentY -= rowHeight
        
        // Прозрачность карандаша
        let pencilOpacityTitleLabel = createLabel("Pencil Transparency:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(pencilOpacityTitleLabel)
        
        pencilOpacitySlider = createSlider(frame: NSRect(x: controlX, y: currentY, width: 250, height: 20))
        pencilOpacitySlider.minValue = 0.1
        pencilOpacitySlider.maxValue = 1.0
        pencilOpacitySlider.doubleValue = Double(CursorSettings.shared.pencilOpacity)
        pencilOpacitySlider.target = self
        pencilOpacitySlider.action = #selector(pencilOpacityChanged)
        contentContainer.addSubview(pencilOpacitySlider)
        
        pencilOpacityLabel = createLabel("\(Int(CursorSettings.shared.pencilOpacity * 100))%", frame: NSRect(x: controlX + 260, y: currentY, width: 60, height: 20))
        contentContainer.addSubview(pencilOpacityLabel)
        currentY -= rowHeight + 5
        
        // Menu Settings Section
        let menuSectionLabel = createSectionLabel("Menu Settings", y: currentY)
        contentContainer.addSubview(menuSectionLabel)
        currentY -= 25
        
        // Тема меню - Switch
        let menuThemeLabel = createLabel("Menu Theme:", frame: NSRect(x: 40, y: currentY, width: labelWidth, height: 20))
        contentContainer.addSubview(menuThemeLabel)
        
        // Switch для переключения темы (Dark/Light)
        let isDark = CursorSettings.shared.menuTheme == .dark
        themeSwitch = NSSwitch(frame: NSRect(x: controlX, y: currentY - 2, width: 51, height: 31))
        themeSwitch.state = isDark ? .off : .on
        themeSwitch.target = self
        themeSwitch.action = #selector(themeSwitchChanged)
        contentContainer.addSubview(themeSwitch)
        
        // Метка для switch (Dark/Light)
        let themeLabel = createLabel(isDark ? "Dark" : "Light", frame: NSRect(x: controlX + 60, y: currentY, width: 100, height: 20))
        themeLabel.tag = 999 // Используем tag для обновления
        contentContainer.addSubview(themeLabel)
        currentY -= rowHeight + 5
        
        // Подсказка о горячих клавишах
        let hintLabel = NSTextField(labelWithString: "💡 Tip: ⌘ + Click opens menu and closes pencil mode")
        hintLabel.frame = NSRect(x: 40, y: currentY, width: 520, height: 20)
        hintLabel.font = NSFont.systemFont(ofSize: 11)
        hintLabel.tag = 1000 // Используем tag для обновления цвета
        let isDarkForHint = CursorSettings.shared.menuTheme == .dark
        hintLabel.textColor = isDarkForHint ? NSColor.labelColor : NSColor(white: 0.1, alpha: 1.0)
        hintLabel.alignment = .left
        contentContainer.addSubview(hintLabel)
        currentY -= 20
        
        // Кнопка "Apply" внизу под всеми элементами
        // Добавляем отступ от нижнего края окна (20px)
        let bottomPadding: CGFloat = 20
        let windowWidth: CGFloat = 600
        let applyButton = NSButton(frame: NSRect(x: windowWidth - 140, y: bottomPadding, width: 120, height: 32))
        applyButton.title = "Apply"
        applyButton.bezelStyle = .rounded
        applyButton.target = self
        applyButton.action = #selector(applyButtonClicked)
        applyButton.keyEquivalent = "\r"
        applyButton.wantsLayer = true
        applyButton.layer?.cornerRadius = 8
        applyButton.layer?.backgroundColor = NSColor.clear.cgColor
        applyButton.autoresizingMask = [.minXMargin, .minYMargin]
        contentContainer.addSubview(applyButton)
        
        // Устанавливаем текущие значения
        let currentColor = CursorSettings.shared.color
        colorPopUp.selectItem(withTitle: currentColor.displayName)
        
        let currentClickColor = CursorSettings.shared.clickColor
        clickColorPopUp.selectItem(withTitle: currentClickColor.displayName)
        
        let currentPencilColor = CursorSettings.shared.pencilColor
        pencilColorPopUp.selectItem(withTitle: currentPencilColor.displayName)
        
        let currentSizeSetting = CursorSettings.shared.size
        sizePopUp.selectItem(withTitle: currentSizeSetting.displayName)
        
        let currentShape = CursorSettings.shared.shape
        shapePopUp.selectItem(withTitle: currentShape.displayName)
        
        let currentInnerGlowStyle = CursorSettings.shared.innerGlowStyle
        innerGlowStylePopUp.selectItem(withTitle: currentInnerGlowStyle.displayName)
    }
    
    private func createLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = frame
        label.font = NSFont.systemFont(ofSize: 13)
        // Устанавливаем цвет в зависимости от темы
        let isDark = CursorSettings.shared.menuTheme == .dark
        label.textColor = isDark ? .labelColor : NSColor(white: 0.1, alpha: 1.0)
        return label
    }
    
    private func createSectionLabel(_ text: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 40, y: y, width: 500, height: 20)
        label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        // Устанавливаем цвет в зависимости от темы
        let isDark = CursorSettings.shared.menuTheme == .dark
        label.textColor = isDark ? .labelColor : NSColor(white: 0.1, alpha: 1.0)
        return label
    }
    
    private func createPopUpButton(frame: NSRect) -> NSPopUpButton {
        let popUp = NSPopUpButton(frame: frame)
        popUp.wantsLayer = true
        popUp.layer?.cornerRadius = 6
        popUp.bezelStyle = .rounded
        return popUp
    }
    
    private func createSlider(frame: NSRect) -> NSSlider {
        let slider = NSSlider(frame: frame)
        return slider
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updatePreview() {
        guard let previewView = previewView else { return }
        previewView.baseColor = CursorSettings.shared.color.color
        previewView.clickColor = CursorSettings.shared.clickColor.color
        previewView.opacity = CursorSettings.shared.opacity
        let newDiameter = CursorSettings.shared.size.diameter
        // Используем точный размер как у реального курсора
        let centerX = previewView.frame.midX
        let centerY = previewView.frame.midY
        previewView.frame = NSRect(
            x: centerX - newDiameter / 2,
            y: centerY - newDiameter / 2,
            width: newDiameter,
            height: newDiameter
        )
        previewView.needsDisplay = true
    }
    
    @objc private func opacityChanged() {
        let newOpacity = CGFloat(opacitySlider.doubleValue)
        CursorSettings.shared.opacity = newOpacity
        opacityLabel.stringValue = "\(Int(newOpacity * 100))%"
        updatePreview()
    }
    
    @objc private func applyButtonClicked() {
        // Закрываем окно настроек
        window?.close()
    }
    
    private func setupColorMenu() {
        colorPopUp.removeAllItems()
        for color in CursorColor.allCases {
            // Создаём изображение-индикатор цвета
            let colorImage = NSImage(size: NSSize(width: 16, height: 16))
            colorImage.lockFocus()
            color.color.setFill()
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 12, height: 12)).fill()
            colorImage.unlockFocus()
            
            let menuItem = NSMenuItem(title: color.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = color
            menuItem.image = colorImage
            colorPopUp.menu?.addItem(menuItem)
        }
    }
    
    private func setupSizeMenu() {
        sizePopUp.removeAllItems()
        for size in CursorSize.allCases {
            let menuItem = NSMenuItem(title: size.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = size
            sizePopUp.menu?.addItem(menuItem)
        }
    }
    
    private func setupShapeMenu() {
        shapePopUp.removeAllItems()
        for shape in CursorShape.allCases {
            let menuItem = NSMenuItem(title: shape.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = shape
            shapePopUp.menu?.addItem(menuItem)
        }
    }
    
    private func setupInnerGlowStyleMenu() {
        innerGlowStylePopUp.removeAllItems()
        for style in InnerGlowStyle.allCases {
            let menuItem = NSMenuItem(title: style.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = style
            innerGlowStylePopUp.menu?.addItem(menuItem)
        }
    }
    
    private func setupClickColorMenu() {
        clickColorPopUp.removeAllItems()
        for color in CursorColor.allCases {
            // Создаём изображение-индикатор цвета
            let colorImage = NSImage(size: NSSize(width: 16, height: 16))
            colorImage.lockFocus()
            color.color.setFill()
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 12, height: 12)).fill()
            colorImage.unlockFocus()
            
            let menuItem = NSMenuItem(title: color.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = color
            menuItem.image = colorImage
            clickColorPopUp.menu?.addItem(menuItem)
        }
    }
    
    @objc private func colorChanged() {
        if let selectedItem = colorPopUp.selectedItem,
           let color = selectedItem.representedObject as? CursorColor {
            CursorSettings.shared.color = color
            updatePreview()
        }
    }
    
    @objc private func sizeChanged() {
        if let selectedItem = sizePopUp.selectedItem,
           let size = selectedItem.representedObject as? CursorSize {
            CursorSettings.shared.size = size
            updatePreview()
        }
    }
    
    @objc private func shapeChanged() {
        if let selectedItem = shapePopUp.selectedItem,
           let shape = selectedItem.representedObject as? CursorShape {
            CursorSettings.shared.shape = shape
            updatePreview()
        }
    }
    
    @objc private func innerGlowStyleChanged() {
        if let selectedItem = innerGlowStylePopUp.selectedItem,
           let style = selectedItem.representedObject as? InnerGlowStyle {
            CursorSettings.shared.innerGlowStyle = style
            updatePreview()
        }
    }
    
    @objc private func outerLineWidthChanged() {
        let newWidth = CGFloat(outerLineWidthSlider.doubleValue)
        CursorSettings.shared.outerLineWidth = newWidth
        outerLineWidthLabel.stringValue = String(format: "%.1f", newWidth)
        updatePreview()
    }
    
    @objc private func clickColorChanged() {
        if let selectedItem = clickColorPopUp.selectedItem,
           let color = selectedItem.representedObject as? CursorColor {
            CursorSettings.shared.clickColor = color
            updatePreview()
        }
    }
    
    private func setupPencilColorMenu() {
        pencilColorPopUp.removeAllItems()
        for color in CursorColor.allCases {
            // Создаём изображение-индикатор цвета
            let colorImage = NSImage(size: NSSize(width: 16, height: 16))
            colorImage.lockFocus()
            color.color.setFill()
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 12, height: 12)).fill()
            colorImage.unlockFocus()
            
            let menuItem = NSMenuItem(title: color.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = color
            menuItem.image = colorImage
            pencilColorPopUp.menu?.addItem(menuItem)
        }
    }
    
    @objc private func pencilColorChanged() {
        if let selectedItem = pencilColorPopUp.selectedItem,
           let color = selectedItem.representedObject as? CursorColor {
            CursorSettings.shared.pencilColor = color
        }
    }
    
    @objc private func pencilLineWidthChanged() {
        let newWidth = CGFloat(pencilLineWidthSlider.doubleValue)
        CursorSettings.shared.pencilLineWidth = newWidth
        pencilLineWidthLabel.stringValue = String(format: "%.1f", newWidth)
    }
    
    @objc private func pencilOpacityChanged() {
        let newOpacity = CGFloat(pencilOpacitySlider.doubleValue)
        CursorSettings.shared.pencilOpacity = newOpacity
        pencilOpacityLabel.stringValue = "\(Int(newOpacity * 100))%"
    }
    
    @objc private func shadowBrightnessChanged() {
        let newBrightness = CGFloat(shadowBrightnessSlider.doubleValue)
        CursorSettings.shared.shadowBrightness = newBrightness
        shadowBrightnessLabel.stringValue = "\(Int(newBrightness * 100))%"
        updatePreview()
    }
    
    
    @objc private func themeSwitchChanged() {
        let newTheme: MenuTheme = themeSwitch.state == .on ? .light : .dark
        CursorSettings.shared.menuTheme = newTheme
        
        // Обновляем метку рядом со switch
        for subview in contentContainer.subviews {
            if let label = subview as? NSTextField, label.tag == 999 {
                label.stringValue = newTheme == .dark ? "Dark" : "Light"
                break
            }
        }
    }
    
    func showWindow() {
        // Останавливаем основной курсор при открытии настроек
        NotificationCenter.default.post(name: .settingsWindowWillOpen, object: nil)
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Обновляем превью при открытии только если оно уже создано
        if previewView != nil {
            updatePreview()
        }
    }
    
    
}

extension SettingsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Возобновляем основной курсор при закрытии настроек
        NotificationCenter.default.post(name: .settingsWindowWillClose, object: nil)
    }
}

extension Notification.Name {
    static let settingsWindowWillOpen = Notification.Name("settingsWindowWillOpen")
    static let settingsWindowWillClose = Notification.Name("settingsWindowWillClose")
}
