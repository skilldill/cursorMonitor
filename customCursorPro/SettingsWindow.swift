import Cocoa

class SettingsWindow: NSWindowController {
    
    private var colorPopUp: NSPopUpButton!
    private var sizePopUp: NSPopUpButton!
    private var opacitySlider: NSSlider!
    private var opacityLabel: NSTextField!
    private var clickColorPopUp: NSPopUpButton!
    private var pencilColorPopUp: NSPopUpButton!
    private var pencilLineWidthSlider: NSSlider!
    private var pencilLineWidthLabel: NSTextField!
    private var pencilOpacitySlider: NSSlider!
    private var pencilOpacityLabel: NSTextField!
    private var previewView: HighlightView!
    private var highlighter: CursorHighlighter?
    
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
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Настройки курсора"
        window.center()
        window.isReleasedWhenClosed = false
        
        let contentView = window.contentView!
        
        // Заголовок превью
        let previewLabel = NSTextField(labelWithString: "Превью:")
        previewLabel.frame = NSRect(x: 20, y: 280, width: 100, height: 20)
        contentView.addSubview(previewLabel)
        
        // Превью курсора - используем точный размер как у реального курсора
        let previewDiameter = CursorSettings.shared.size.diameter
        let previewFrame = NSRect(x: 165, y: 220, width: previewDiameter, height: previewDiameter)
        previewView = HighlightView(frame: previewFrame)
        previewView.wantsLayer = true
        previewView.baseColor = CursorSettings.shared.color.color
        previewView.clickColor = CursorSettings.shared.clickColor.color
        previewView.opacity = CursorSettings.shared.opacity
        contentView.addSubview(previewView)
        
        // Заголовок цвета
        let colorLabel = NSTextField(labelWithString: "Цвет курсора:")
        colorLabel.frame = NSRect(x: 20, y: 190, width: 150, height: 20)
        contentView.addSubview(colorLabel)
        
        // Выпадающий список цветов
        colorPopUp = NSPopUpButton(frame: NSRect(x: 180, y: 185, width: 250, height: 26))
        setupColorMenu()
        colorPopUp.target = self
        colorPopUp.action = #selector(colorChanged)
        contentView.addSubview(colorPopUp)
        
        // Заголовок цвета клика
        let clickColorLabel = NSTextField(labelWithString: "Цвет при клике:")
        clickColorLabel.frame = NSRect(x: 20, y: 150, width: 150, height: 20)
        contentView.addSubview(clickColorLabel)
        
        // Выпадающий список цветов клика
        clickColorPopUp = NSPopUpButton(frame: NSRect(x: 180, y: 145, width: 250, height: 26))
        setupClickColorMenu()
        clickColorPopUp.target = self
        clickColorPopUp.action = #selector(clickColorChanged)
        contentView.addSubview(clickColorPopUp)
        
        // Заголовок размера
        let sizeLabel = NSTextField(labelWithString: "Размер курсора:")
        sizeLabel.frame = NSRect(x: 20, y: 110, width: 150, height: 20)
        contentView.addSubview(sizeLabel)
        
        // Выпадающий список размеров
        sizePopUp = NSPopUpButton(frame: NSRect(x: 180, y: 105, width: 250, height: 26))
        setupSizeMenu()
        sizePopUp.target = self
        sizePopUp.action = #selector(sizeChanged)
        contentView.addSubview(sizePopUp)
        
        // Заголовок прозрачности
        let opacityTitleLabel = NSTextField(labelWithString: "Прозрачность:")
        opacityTitleLabel.frame = NSRect(x: 20, y: 70, width: 150, height: 20)
        contentView.addSubview(opacityTitleLabel)
        
        // Слайдер прозрачности
        opacitySlider = NSSlider(frame: NSRect(x: 180, y: 65, width: 200, height: 20))
        opacitySlider.minValue = 0.1
        opacitySlider.maxValue = 1.0
        opacitySlider.doubleValue = Double(CursorSettings.shared.opacity)
        opacitySlider.target = self
        opacitySlider.action = #selector(opacityChanged)
        contentView.addSubview(opacitySlider)
        
        // Метка значения прозрачности
        opacityLabel = NSTextField(labelWithString: "\(Int(CursorSettings.shared.opacity * 100))%")
        opacityLabel.frame = NSRect(x: 390, y: 65, width: 40, height: 20)
        opacityLabel.alignment = .left
        contentView.addSubview(opacityLabel)
        
        // Разделитель для настроек карандаша
        let separator = NSBox(frame: NSRect(x: 20, y: 30, width: 410, height: 1))
        separator.boxType = .separator
        contentView.addSubview(separator)
        
        // Заголовок настроек карандаша
        let pencilTitleLabel = NSTextField(labelWithString: "Настройки карандаша:")
        pencilTitleLabel.frame = NSRect(x: 20, y: 10, width: 200, height: 20)
        pencilTitleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        contentView.addSubview(pencilTitleLabel)
        
        // Заголовок цвета карандаша
        let pencilColorLabel = NSTextField(labelWithString: "Цвет карандаша:")
        pencilColorLabel.frame = NSRect(x: 20, y: 450, width: 150, height: 20)
        contentView.addSubview(pencilColorLabel)
        
        // Выпадающий список цветов карандаша
        pencilColorPopUp = NSPopUpButton(frame: NSRect(x: 180, y: 445, width: 250, height: 26))
        setupPencilColorMenu()
        pencilColorPopUp.target = self
        pencilColorPopUp.action = #selector(pencilColorChanged)
        contentView.addSubview(pencilColorPopUp)
        
        // Заголовок толщины линии карандаша
        let pencilLineWidthTitleLabel = NSTextField(labelWithString: "Толщина линии:")
        pencilLineWidthTitleLabel.frame = NSRect(x: 20, y: 410, width: 150, height: 20)
        contentView.addSubview(pencilLineWidthTitleLabel)
        
        // Слайдер толщины линии карандаша
        pencilLineWidthSlider = NSSlider(frame: NSRect(x: 180, y: 405, width: 200, height: 20))
        pencilLineWidthSlider.minValue = 1.0
        pencilLineWidthSlider.maxValue = 20.0
        pencilLineWidthSlider.doubleValue = Double(CursorSettings.shared.pencilLineWidth)
        pencilLineWidthSlider.target = self
        pencilLineWidthSlider.action = #selector(pencilLineWidthChanged)
        contentView.addSubview(pencilLineWidthSlider)
        
        // Метка значения толщины линии
        pencilLineWidthLabel = NSTextField(labelWithString: String(format: "%.1f", CursorSettings.shared.pencilLineWidth))
        pencilLineWidthLabel.frame = NSRect(x: 390, y: 405, width: 40, height: 20)
        pencilLineWidthLabel.alignment = .left
        contentView.addSubview(pencilLineWidthLabel)
        
        // Заголовок прозрачности карандаша
        let pencilOpacityTitleLabel = NSTextField(labelWithString: "Прозрачность карандаша:")
        pencilOpacityTitleLabel.frame = NSRect(x: 20, y: 370, width: 150, height: 20)
        contentView.addSubview(pencilOpacityTitleLabel)
        
        // Слайдер прозрачности карандаша
        pencilOpacitySlider = NSSlider(frame: NSRect(x: 180, y: 365, width: 200, height: 20))
        pencilOpacitySlider.minValue = 0.1
        pencilOpacitySlider.maxValue = 1.0
        pencilOpacitySlider.doubleValue = Double(CursorSettings.shared.pencilOpacity)
        pencilOpacitySlider.target = self
        pencilOpacitySlider.action = #selector(pencilOpacityChanged)
        contentView.addSubview(pencilOpacitySlider)
        
        // Метка значения прозрачности карандаша
        pencilOpacityLabel = NSTextField(labelWithString: "\(Int(CursorSettings.shared.pencilOpacity * 100))%")
        pencilOpacityLabel.frame = NSRect(x: 390, y: 365, width: 40, height: 20)
        pencilOpacityLabel.alignment = .left
        contentView.addSubview(pencilOpacityLabel)
        
        // Кнопка "Применить"
        let applyButton = NSButton(frame: NSRect(x: 320, y: 320, width: 110, height: 32))
        applyButton.title = "Применить"
        applyButton.bezelStyle = .rounded
        applyButton.target = self
        applyButton.action = #selector(applyButtonClicked)
        applyButton.keyEquivalent = "\r" // Enter для применения
        contentView.addSubview(applyButton)
        
        // Устанавливаем текущие значения
        let currentColor = CursorSettings.shared.color
        colorPopUp.selectItem(withTitle: currentColor.displayName)
        
        let currentClickColor = CursorSettings.shared.clickColor
        clickColorPopUp.selectItem(withTitle: currentClickColor.displayName)
        
        let currentPencilColor = CursorSettings.shared.pencilColor
        pencilColorPopUp.selectItem(withTitle: currentPencilColor.displayName)
        
        let currentSizeSetting = CursorSettings.shared.size
        sizePopUp.selectItem(withTitle: currentSizeSetting.displayName)
        
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
            name: .cursorOpacityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreview),
            name: .cursorClickColorChanged,
            object: nil
        )
        
        self.window = window
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updatePreview() {
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
    
    func showWindow() {
        // Останавливаем основной курсор при открытии настроек
        NotificationCenter.default.post(name: .settingsWindowWillOpen, object: nil)
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Обновляем превью при открытии
        updatePreview()
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

