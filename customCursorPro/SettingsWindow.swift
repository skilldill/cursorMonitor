import Cocoa

class SettingsWindow: NSWindowController {
    
    private var colorPopUp: NSPopUpButton!
    private var sizePopUp: NSPopUpButton!
    private var opacitySlider: NSSlider!
    private var opacityLabel: NSTextField!
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
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 360),
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
        previewLabel.frame = NSRect(x: 20, y: 240, width: 100, height: 20)
        contentView.addSubview(previewLabel)
        
        // Превью курсора - используем точный размер как у реального курсора
        let previewDiameter = CursorSettings.shared.size.diameter
        let previewFrame = NSRect(x: 165, y: 180, width: previewDiameter, height: previewDiameter)
        previewView = HighlightView(frame: previewFrame)
        previewView.wantsLayer = true
        previewView.baseColor = CursorSettings.shared.color.color
        previewView.opacity = CursorSettings.shared.opacity
        contentView.addSubview(previewView)
        
        // Заголовок цвета
        let colorLabel = NSTextField(labelWithString: "Цвет курсора:")
        colorLabel.frame = NSRect(x: 20, y: 150, width: 150, height: 20)
        contentView.addSubview(colorLabel)
        
        // Выпадающий список цветов
        colorPopUp = NSPopUpButton(frame: NSRect(x: 180, y: 145, width: 250, height: 26))
        setupColorMenu()
        colorPopUp.target = self
        colorPopUp.action = #selector(colorChanged)
        contentView.addSubview(colorPopUp)
        
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
        
        // Кнопка "Применить"
        let applyButton = NSButton(frame: NSRect(x: 320, y: 20, width: 110, height: 32))
        applyButton.title = "Применить"
        applyButton.bezelStyle = .rounded
        applyButton.target = self
        applyButton.action = #selector(applyButtonClicked)
        applyButton.keyEquivalent = "\r" // Enter для применения
        contentView.addSubview(applyButton)
        
        // Устанавливаем текущие значения
        let currentColor = CursorSettings.shared.color
        colorPopUp.selectItem(withTitle: currentColor.displayName)
        
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
        
        self.window = window
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updatePreview() {
        previewView.baseColor = CursorSettings.shared.color.color
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

