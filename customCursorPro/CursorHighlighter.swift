import Cocoa

final class CursorHighlighter {

    private var window: NSWindow?
    private var highlightView: HighlightView?
    private var menuWindow: NSWindow?
    private var menuView: MenuViewWrapper?
    private var noteInputWindow: NoteInputWindow?
    private var notesViewWindow: NotesViewWindow?
    private var drawingWindow: DrawingWindow?
    private var pencilSettingsWindow: NSWindow?
    private var trailWindows: [TrailWindow] = []
    private var mouseMoveMonitor: Any?
    private var clickDownMonitor: Any?
    private var clickUpMonitor: Any?
    private var leftMouseDraggedMonitor: Any?
    private var isLeftButtonPressed = false
    private var rightClickDownMonitor: Any?
    private var rightClickUpMonitor: Any?
    private var middleButtonDownMonitor: Any?
    private var middleButtonUpMonitor: Any?
    private var keyDownMonitor: Any?
    private var menuClickMonitor: Any?

    private var diameter: CGFloat {
        return CursorSettings.shared.size.diameter
    }
    
    // Вычисляет размер окна с учетом тени (если включен режим свечения)
    private func calculateWindowSize(withGlow: Bool) -> CGFloat {
        let baseSize = diameter
        if withGlow && CursorSettings.shared.cursorGlowEnabled {
            // Радиус размытия тени = outerLineWidth * 2.5
            let blurRadius = CursorSettings.shared.outerLineWidth * 2.5
            // Добавляем тень с каждой стороны (blurRadius * 2) + дополнительный запас для безопасности
            let padding: CGFloat = blurRadius * 2 + 20 // Увеличиваем запас, чтобы тень точно не обрезалась
            return baseSize + padding
        }
        return baseSize
    }
    
    // Размер окна для режима карандаша (радиус * 2 + небольшой отступ для обводки)
    private var pencilWindowSize: CGFloat {
        let lineWidth = CursorSettings.shared.pencilLineWidth
        // Размер окна = диаметр окружности + небольшой отступ (4px для обводки)
        return max(lineWidth + 4, 20) // Минимум 20px для видимости
    }
    
    // Заморозка курсора
    private var isFrozen = false
    private var frozenPosition: NSPoint?
    
    // Скрытие курсора при вводе текста
    private var isHiddenForTextInput = false
    
    // Отслеживание состояния колесика мыши
    private var isMiddleButtonPressed = false
    
    // Позиция для меню (справа от курсора)
    private let menuOffset: CGFloat = 20
    
    // Оригинальный размер окна для восстановления после режима карандаша
    private var originalWindowSize: CGFloat = 0
    
    // Таймер для отслеживания неактивности курсора
    private var inactivityTimer: Timer?
    private var isFadingOut = false

    private(set) var isRunning: Bool = false
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sizeChanged),
            name: .cursorSizeChanged,
            object: nil
        )
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
            selector: #selector(hideWhenInactiveChanged),
            name: .hideWhenInactiveChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cursorPositionUpdate),
            name: .cursorPositionUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cursorGlowEnabledChanged),
            name: .cursorGlowEnabledChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cursorTrailEnabledChanged),
            name: .cursorTrailEnabledChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inactivityTimeoutChanged),
            name: .inactivityTimeoutChanged,
            object: nil
        )
    }
    
    @objc private func sizeChanged() {
        // Пересоздаём окно с новым размером
        if isRunning {
            // Сохраняем состояние режима карандаша
            let wasPencilMode = highlightView?.isPencilMode ?? false
            
            // Закрываем старое окно
            window?.orderOut(nil)
            window = nil
            highlightView = nil
            
            // Пересоздаём окно с новым размером
            createWindowIfNeeded()
            
            // Восстанавливаем режим карандаша, если он был активен
            if wasPencilMode {
                highlightView?.isPencilMode = true
                highlightView?.pencilModeColor = CursorSettings.shared.pencilColor.color
            } else {
                // Обновляем originalWindowSize, если режим карандаша не активен
                originalWindowSize = diameter
            }
            
            updatePositionToMouse()
        }
    }
    
    @objc private func colorChanged() {
        // Обновляем цвет курсора
        highlightView?.baseColor = CursorSettings.shared.color.color
    }
    
    @objc private func opacityChanged() {
        // Обновляем прозрачность курсора
        highlightView?.opacity = CursorSettings.shared.opacity
    }
    
    @objc private func clickColorChanged() {
        highlightView?.clickColor = CursorSettings.shared.clickColor.color
    }
    
    @objc private func shapeChanged() {
        // Просто перерисовываем курсор с новой формой
        highlightView?.needsDisplay = true
    }
    
    @objc private func pencilLineWidthChanged() {
        // Если карандаш активен, обновляем размер окна и перерисовываем курсор
        if drawingWindow?.isDrawing == true, let window = window, let highlightView = highlightView {
            let pencilSize = pencilWindowSize
            let currentPos = NSEvent.mouseLocation
            let newOrigin = NSPoint(
                x: currentPos.x - pencilSize / 2,
                y: currentPos.y - pencilSize / 2
            )
            window.setFrame(NSRect(x: newOrigin.x, y: newOrigin.y, width: pencilSize, height: pencilSize), display: true)
            highlightView.frame = NSRect(x: 0, y: 0, width: pencilSize, height: pencilSize)
            highlightView.needsDisplay = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        createWindowIfNeeded()
        // Создаем окна трека заранее, если режим трека включен
        if CursorSettings.shared.cursorTrailEnabled {
            createTrailWindowsIfNeeded()
        }
        startMonitoring()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        if let monitor = mouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = clickDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = clickUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = rightClickDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = rightClickUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = middleButtonDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = middleButtonUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = menuClickMonitor {
            NSEvent.removeMonitor(monitor)
        }

        mouseMoveMonitor = nil
        clickDownMonitor = nil
        clickUpMonitor = nil
        rightClickDownMonitor = nil
        rightClickUpMonitor = nil
        middleButtonDownMonitor = nil
        middleButtonUpMonitor = nil
        keyDownMonitor = nil
        menuClickMonitor = nil

        window?.orderOut(nil)
        menuWindow?.orderOut(nil)
        drawingWindow?.stopDrawing()
        pencilSettingsWindow?.orderOut(nil)
        for trailWindow in trailWindows {
            trailWindow.endTrail()
            trailWindow.orderOut(nil)
        }
        trailWindows.removeAll()
        
        // Останавливаем таймер неактивности
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        
        // Сброс состояния
        isFrozen = false
        frozenPosition = nil
        isMiddleButtonPressed = false
        isFadingOut = false
    }

    // Создаём прозрачное окно поверх всех экранов/спейсов
    func createWindowIfNeeded() {
        // Если окно уже существует, закрываем его перед пересозданием
        if window != nil {
            window?.orderOut(nil)
            window = nil
            highlightView = nil
        }

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = calculateWindowSize(withGlow: true)
        let initialRect = NSRect(
            x: screenFrame.midX - windowSize / 2,
            y: screenFrame.midY - windowSize / 2,
            width: windowSize,
            height: windowSize
        )

        // ВАЖНО: используем NSPanel, а не NSWindow
        let panel = NSPanel(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // По умолчанию игнорируем клики (чтобы они проходили сквозь)
        // Когда курсор заморожен, изменим это на false
        panel.ignoresMouseEvents = true

        // Уровень поверх всего (выше окна рисования)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)

        // Поведение в Spaces / full screen
        panel.collectionBehavior = [
            .canJoinAllSpaces,    // есть во всех рабочих столах и полноэкранных спейсах
            .fullScreenAuxiliary, // может показываться вместе с fullscreen окнами
            .ignoresCycle         // не мешает cmd+`
        ]

        let viewSize = calculateWindowSize(withGlow: true)
        let view = HighlightView(frame: NSRect(x: 0, y: 0, width: viewSize, height: viewSize))
        view.wantsLayer = true
        // Отключаем обрезку содержимого, чтобы тень не обрезалась
        view.layer?.masksToBounds = false
        view.layer?.opacity = Float(CursorSettings.shared.opacity)
        view.baseColor = CursorSettings.shared.color.color
        view.clickColor = CursorSettings.shared.clickColor.color
        view.opacity = CursorSettings.shared.opacity

        panel.contentView = view
        panel.orderFrontRegardless()
        
        // Убеждаемся, что окно поддерживает анимацию
        panel.isOpaque = false
        panel.hasShadow = false
        panel.backgroundColor = .clear

        self.window = panel
        self.highlightView = view
        // Сохраняем оригинальный размер окна (базовый размер без тени)
        self.originalWindowSize = diameter
    }


    private func startMonitoring() {
        // Двигаем за мышью по всем экранам
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] _ in
            // Показываем курсор при движении мыши, если он был скрыт для ввода текста
            self?.updatePositionToMouse()
        }
        
        // Запускаем таймер неактивности при старте
        resetInactivityTimer()

        // Левая кнопка мыши: mouseDown (для визуального эффекта или открытия меню с Command)
        clickDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [weak self] event in
            guard let self = self else { return }
            // Если нажата Command, открываем/закрываем меню или отключаем карандаш
            if event.modifierFlags.contains(.command) {
                // Если карандаш включен, отключаем его (приоритет над меню)
                if self.drawingWindow?.isDrawing == true {
                    self.stopPencil()
                    return
                }
                // Если меню уже открыто, закрываем его
                if self.menuWindow?.isVisible == true {
                    self.hideMenu()
                } else {
                    // Иначе открываем меню
                    self.showMenu()
                }
            } else {
                // Обычный клик - показываем визуальный эффект
                self.highlightView?.beginClick()
                
                // Если включен режим трека, начинаем трек
                if CursorSettings.shared.cursorTrailEnabled {
                    self.isLeftButtonPressed = true
                    let location = NSEvent.mouseLocation
                    self.startTrail(at: location)
                }
            }
            // Показываем курсор при клике
            if self.isFadingOut {
                self.showCursorAnimated()
            }
            self.resetInactivityTimer()
        }

        // Левая кнопка мыши: mouseUp (для визуального эффекта)
        clickUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseUp]
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isLeftButtonPressed = false
            self.highlightView?.endClick()
            
            // Завершаем трек если он был активен
            if CursorSettings.shared.cursorTrailEnabled {
                self.endTrail()
            }
            
            // Сбрасываем таймер при отпускании кнопки
            self.resetInactivityTimer()
        }
        
        // Отслеживание движения мыши с зажатой левой кнопкой для трека
        leftMouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged]
        ) { [weak self] event in
            guard let self = self else { return }
            if CursorSettings.shared.cursorTrailEnabled && self.isLeftButtonPressed {
                let location = NSEvent.mouseLocation
                self.addTrailPoint(location)
            }
        }
        
        // Отслеживание нажатия колесика для комбинации с правой кнопкой и визуального эффекта
        middleButtonDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.otherMouseDown]
        ) { [weak self] event in
            guard let self = self else { return }
            if event.buttonNumber == 2 {
                self.isMiddleButtonPressed = true
                // Проверяем, не зажата ли правая кнопка - если нет, показываем визуальный эффект
                let pressedButtons = NSEvent.pressedMouseButtons
                if pressedButtons & 0x2 == 0 { // Правая кнопка не зажата (бит 0x2)
                    self.highlightView?.beginClick()
                }
                // Показываем курсор при клике
                if self.isFadingOut {
                    self.showCursorAnimated()
                }
                self.resetInactivityTimer()
            }
        }
        
        // Отслеживание отпускания колесика
        middleButtonUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.otherMouseUp]
        ) { [weak self] event in
            guard let self = self else { return }
            if event.buttonNumber == 2 {
                self.isMiddleButtonPressed = false
                // Проверяем, не зажата ли правая кнопка - если нет, завершаем визуальный эффект
                let pressedButtons = NSEvent.pressedMouseButtons
                if pressedButtons & 0x2 == 0 { // Правая кнопка не зажата
                    self.highlightView?.endClick()
                }
            }
        }
        
        // Правая кнопка мыши: mouseDown (для визуального эффекта как у левой кнопки)
        rightClickDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.rightMouseDown]
        ) { [weak self] event in
            guard let self = self else { return }
            // Всегда показываем визуальный эффект при нажатии правой кнопки
            // (работает как отдельно, так и в комбинации с колесиком)
            self.highlightView?.beginClick()
            // Показываем курсор при клике
            if self.isFadingOut {
                self.showCursorAnimated()
            }
            self.resetInactivityTimer()
        }
        
        // Правая кнопка мыши: mouseUp (для визуального эффекта)
        rightClickUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.rightMouseUp]
        ) { [weak self] _ in
            guard let self = self else { return }
            // Проверяем, зажато ли колесико - если нет, завершаем эффект
            // Если колесико зажато, эффект продолжит работать до его отпускания
            if !self.isMiddleButtonPressed {
                self.highlightView?.endClick()
            }
        }
        
        // Отслеживание ввода текста для скрытия курсора
        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] _ in
            guard let self = self else { return }
            // Проверяем, активен ли текстовый ввод
            if self.isTextInputActive() && !self.isHiddenForTextInput {
                self.hideCursorForTextInput()
            } else {
                // Сбрасываем таймер при нажатии клавиш (если не в текстовом поле)
                self.resetInactivityTimer()
            }
        }
        
        // Также отслеживаем клики по текстовым полям
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidBecomeFirstResponder),
            name: NSControl.textDidBeginEditingNotification,
            object: nil
        )
    }
    
    @objc private func textFieldDidBecomeFirstResponder() {
        // Скрываем курсор когда текстовое поле получает фокус
        if !isHiddenForTextInput {
            hideCursorForTextInput()
        }
    }
    
    private func isTextInputActive() -> Bool {
        // Проверяем, есть ли активное окно с текстовым полем
        // Проверяем, является ли первый респондер текстовым полем
        if let keyWindow = NSApp.keyWindow,
           let firstResponder = keyWindow.firstResponder {
            // Проверяем, является ли респондер текстовым полем или текстовым представлением
            return firstResponder is NSTextView || firstResponder is NSTextField
        }
        
        return false
    }
    
    private func hideCursorForTextInput() {
        isHiddenForTextInput = true
        window?.orderOut(nil)
    }
    
    private func showCursorForTextInput() {
        isHiddenForTextInput = false
        if !isFrozen {
            window?.orderFrontRegardless()
            updatePositionToMouse()
        }
    }
    
    private func showMenu() {
        let currentPos = NSEvent.mouseLocation
        
        if menuWindow == nil {
            createMenuWindow()
        }
        
        guard let menuWindow = menuWindow else { return }
        
        // Позиционируем меню справа от курсора (горизонтальная раскладка)
        let menuWidth: CGFloat = 176
        let menuHeight: CGFloat = 80
        let shadowPadding: CGFloat = 20 // Отступ для тени
        let totalWidth = menuWidth + shadowPadding * 2
        let totalHeight = menuHeight + shadowPadding * 2
        
        // NSEvent.mouseLocation и setFrameOrigin используют одну систему координат:
        // (0,0) находится в левом нижнем углу основного экрана
        // Y увеличивается вверх
        
        // Вычисляем позицию меню справа от курсора
        var menuX = currentPos.x + menuOffset
        // Центрируем меню по вертикали относительно курсора
        var menuY = currentPos.y - menuHeight / 2
        
        // Находим экран, на котором находится курсор, для проверки границ
        var targetScreen = NSScreen.main
        for screen in NSScreen.screens {
            if screen.frame.contains(currentPos) {
                targetScreen = screen
                break
            }
        }
        
        if let screen = targetScreen {
            let screenFrame = screen.frame
            
            // Учитываем shadowPadding при позиционировании
            menuX -= shadowPadding
            menuY -= shadowPadding
            
            // Проверяем, не выходит ли меню за правый край экрана
            if menuX + totalWidth > screenFrame.maxX {
                // Если выходит, показываем слева от курсора
                menuX = currentPos.x - totalWidth - menuOffset + shadowPadding
            }
            
            // Проверяем, не выходит ли меню за левый край экрана
            if menuX < screenFrame.minX {
                menuX = screenFrame.minX + 10
            }
            
            // Проверяем, не выходит ли меню за верхний край экрана
            if menuY + totalHeight > screenFrame.maxY {
                menuY = screenFrame.maxY - totalHeight - 10
            }
            
            // Проверяем, не выходит ли меню за нижний край экрана
            if menuY < screenFrame.minY {
                menuY = screenFrame.minY + 10
            }
        }
        
        menuWindow.setFrame(
            NSRect(x: menuX, y: menuY, width: totalWidth, height: totalHeight),
            display: true
        )
        menuWindow.orderFrontRegardless()
        
        // Добавляем монитор для закрытия меню при клике вне его
        setupMenuClickMonitor()
    }
    
    private func setupMenuClickMonitor() {
        // Удаляем предыдущий монитор, если он есть
        if let monitor = menuClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Добавляем монитор для кликов вне меню
        menuClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [weak self] event in
            guard let self = self,
                  let menuWindow = self.menuWindow,
                  menuWindow.isVisible else {
                return
            }
            
            // Проверяем, был ли клик вне окна меню
            let clickLocation = NSEvent.mouseLocation
            let menuFrame = menuWindow.frame
            
            // Если клик был вне меню, закрываем его с небольшой задержкой,
            // чтобы кнопки меню успели обработать клик
            if !menuFrame.contains(clickLocation) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    // Проверяем еще раз, что меню все еще видимо
                    // (если пользователь кликнул на кнопку, меню могло закрыться)
                    if let menuWindow = self?.menuWindow, menuWindow.isVisible {
                        self?.hideMenu()
                    }
                }
            }
        }
    }
    
    private func hideMenu() {
        menuWindow?.orderOut(nil)
        // Удаляем монитор кликов при закрытии меню
        if let monitor = menuClickMonitor {
            NSEvent.removeMonitor(monitor)
            menuClickMonitor = nil
        }
    }
    
    private func createMenuWindow() {
        let menuWidth: CGFloat = 176 // Уменьшили ширину, так как теперь 2 кнопки вместо 3
        let menuHeight: CGFloat = 80
        let shadowPadding: CGFloat = 20 // Отступ для тени
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: menuWidth + shadowPadding * 2, height: menuHeight + shadowPadding * 2),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        
        panel.level = .screenSaver
        
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        
        // Убеждаемся, что contentView не обрезает тень
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.masksToBounds = false
        
        let menuView = MenuViewWrapper(frame: NSRect(x: shadowPadding, y: shadowPadding, width: menuWidth, height: menuHeight))
        
        // Устанавливаем обработчики для кнопок меню
        menuView.onPencilClick = { [weak self] in
            self?.startPencil()
        }
        menuView.onTrailToggle = { [weak self] in
            // Переключение уже произошло в SwiftUI view
            // Здесь можно добавить дополнительную логику, если нужно
        }
        
        panel.contentView = NSView(frame: panel.contentView!.bounds)
        panel.contentView?.addSubview(menuView)
        self.menuWindow = panel
        self.menuView = menuView
    }
    
    private func openSafari() {
        if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            NSWorkspace.shared.open(safariURL)
        }
        hideMenu()
    }
    
    private func showNotesViewWindow() {
        // Закрываем меню перед открытием окна просмотра
        hideMenu()
        
        // Создаем окно просмотра заметок, если его еще нет
        if notesViewWindow == nil {
            notesViewWindow = NotesViewWindow()
            notesViewWindow?.onEditNote = { [weak self] note in
                self?.editNote(note)
            }
        }
        
        notesViewWindow?.showWindow()
    }
    
    private func editNote(_ note: Note) {
        // Создаем окно ввода заметки, если его еще нет
        if noteInputWindow == nil {
            noteInputWindow = NoteInputWindow()
            noteInputWindow?.onSave = { [weak self] text in
                self?.saveNote(text: text)
            }
            noteInputWindow?.onUpdate = { [weak self] noteId, text in
                self?.updateNote(noteId: noteId, text: text)
            }
        }
        
        noteInputWindow?.showWindowForEditing(note: note)
    }
    
    private func updateNote(noteId: UUID, text: String) {
        NotesStorage.shared.updateNote(withId: noteId, newText: text)
        // Обновляем окно просмотра заметок, если оно открыто
        notesViewWindow?.showWindow()
    }
    
    private func openCalculator() {
        if let calcURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.calculator") {
            NSWorkspace.shared.open(calcURL)
        }
        hideMenu()
    }
    
    private func showNoteInputWindow() {
        // Закрываем меню перед открытием окна ввода
        hideMenu()
        
        // Создаем окно ввода заметки, если его еще нет
        if noteInputWindow == nil {
            noteInputWindow = NoteInputWindow()
            noteInputWindow?.onSave = { [weak self] text in
                self?.saveNote(text: text)
            }
            noteInputWindow?.onUpdate = { [weak self] noteId, text in
                self?.updateNote(noteId: noteId, text: text)
            }
        }
        
        noteInputWindow?.showWindowForCreating()
    }
    
    private func saveNote(text: String) {
        let note = Note(text: text)
        NotesStorage.shared.addNote(note)
    }
    
    private func startPencil() {
        // Если карандаш уже включен, ничего не делаем
        if drawingWindow?.isDrawing == true {
            hideMenu()
            return
        }
        
        // Включаем карандаш
        if drawingWindow == nil {
            drawingWindow = DrawingWindow()
            drawingWindow?.onStopDrawing = { [weak self] in
                self?.stopPencil()
            }
        }
        
        // Переключаем курсор в режим карандаша
        if let window = window, let highlightView = highlightView {
            // Сохраняем оригинальный размер (базовый размер без тени)
            originalWindowSize = diameter
            
            // Устанавливаем режим карандаша
            highlightView.isPencilMode = true
            highlightView.pencilModeColor = CursorSettings.shared.pencilColor.color
            
            // Изменяем размер окна в зависимости от толщины карандаша
            let pencilSize = pencilWindowSize
            let currentPos = NSEvent.mouseLocation
            let newOrigin = NSPoint(
                x: currentPos.x - pencilSize / 2,
                y: currentPos.y - pencilSize / 2
            )
            window.setFrame(NSRect(x: newOrigin.x, y: newOrigin.y, width: pencilSize, height: pencilSize), display: true)
            // Обновляем размер view, чтобы он соответствовал новому размеру окна
            highlightView.frame = NSRect(x: 0, y: 0, width: pencilSize, height: pencilSize)
            highlightView.needsDisplay = true
            window.orderFrontRegardless()
            // Обновляем позицию курсора
            updatePositionToMouse()
        }
        
        // Запускаем рисование
        drawingWindow?.startDrawing()
        hideMenu()
        
        // Показываем панель настроек карандаша
        showPencilSettingsPanel()
    }
    
    private func stopPencil() {
        // Выключаем карандаш
        drawingWindow?.stopDrawing()
        
        // Возвращаем курсор в обычный режим
        if let window = window, let highlightView = highlightView {
            // Выключаем режим карандаша
            highlightView.isPencilMode = false
            
            // Восстанавливаем оригинальный размер окна с учетом тени
            let restoredSize = calculateWindowSize(withGlow: true)
            let currentPos = NSEvent.mouseLocation
            let newOrigin = NSPoint(
                x: currentPos.x - restoredSize / 2,
                y: currentPos.y - restoredSize / 2
            )
            window.setFrame(NSRect(x: newOrigin.x, y: newOrigin.y, width: restoredSize, height: restoredSize), display: true)
            // Восстанавливаем размер view
            highlightView.frame = NSRect(x: 0, y: 0, width: restoredSize, height: restoredSize)
            highlightView.needsDisplay = true
        }
        
        // Показываем курсор снова
        if isRunning {
            window?.orderFrontRegardless()
            updatePositionToMouse()
        }
        hideMenu()
        
        // Скрываем панель настроек карандаша
        hidePencilSettingsPanel()
    }

    // Позиционирование окна по глобальным координатам мыши
    private func updatePositionToMouse() {
        guard let window = window, !isHiddenForTextInput else { return }

        // Показываем курсор при движении мыши
        if isFadingOut {
            showCursorAnimated()
        }
        
        // Сбрасываем таймер неактивности
        resetInactivityTimer()

        // Глобальные координаты курсора (одна система для всех мониторов)
        let location = NSEvent.mouseLocation
        
        // Определяем размер окна в зависимости от режима карандаша
        let currentWindowSize: CGFloat
        if highlightView?.isPencilMode == true {
            currentWindowSize = pencilWindowSize // Размер для режима карандаша (зависит от толщины)
        } else {
            currentWindowSize = calculateWindowSize(withGlow: true) // Обычный размер с учетом тени
        }
        
        // Обновляем размер окна, если он изменился (например, при переключении режима или включении свечения)
        if window.frame.width != currentWindowSize {
            let newOrigin = NSPoint(
                x: location.x - currentWindowSize / 2,
                y: location.y - currentWindowSize / 2
            )
            window.setFrame(NSRect(x: newOrigin.x, y: newOrigin.y, width: currentWindowSize, height: currentWindowSize), display: true)
            // Обновляем размер view
            if let highlightView = highlightView {
                highlightView.frame = NSRect(x: 0, y: 0, width: currentWindowSize, height: currentWindowSize)
                highlightView.needsDisplay = true
            }
        } else {
            // Просто обновляем позицию
            let newOrigin = NSPoint(
                x: location.x - currentWindowSize / 2,
                y: location.y - currentWindowSize / 2
            )
            window.setFrameOrigin(newOrigin)
        }

        window.orderFrontRegardless()
    }
    
    // Сброс таймера неактивности
    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        
        // Запускаем таймер только если включена настройка скрытия при неактивности
        if CursorSettings.shared.hideWhenInactive {
            let timeout = CursorSettings.shared.inactivityTimeout
            inactivityTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
                self?.hideCursorAnimated()
            }
        }
    }
    
    // Плавное скрытие курсора
    private func hideCursorAnimated() {
        guard let window = window, let view = highlightView, CursorSettings.shared.hideWhenInactive else { return }
        guard !isHiddenForTextInput, !isFrozen else { return }
        
        isFadingOut = true
        
        // Анимируем через layer для более плавного перехода
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = view.layer?.opacity ?? 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = 0.2
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fadeOutAnimation.fillMode = .forwards
        fadeOutAnimation.isRemovedOnCompletion = false
        
        // Также анимируем alphaValue окна
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0.0
            view.layer?.add(fadeOutAnimation, forKey: "fadeOut")
        }, completionHandler: {
            view.layer?.opacity = 0.0
        })
    }
    
    // Плавное показ курсора
    private func showCursorAnimated() {
        guard let window = window, let view = highlightView else { return }
        
        isFadingOut = false
        
        // Анимируем через layer для более плавного перехода
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = view.layer?.opacity ?? 0.0
        fadeInAnimation.toValue = Float(CursorSettings.shared.opacity)
        fadeInAnimation.duration = 0.3
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fadeInAnimation.fillMode = .forwards
        fadeInAnimation.isRemovedOnCompletion = false
        
        // Также анимируем alphaValue окна
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1.0
            view.layer?.add(fadeInAnimation, forKey: "fadeIn")
        }, completionHandler: {
            view.layer?.opacity = Float(CursorSettings.shared.opacity)
        })
    }
    
    @objc private func hideWhenInactiveChanged() {
        if !CursorSettings.shared.hideWhenInactive {
            // Если настройка выключена, показываем курсор
            inactivityTimer?.invalidate()
            inactivityTimer = nil
            if isFadingOut {
                showCursorAnimated()
            }
        } else {
            // Если настройка включена, запускаем таймер
            resetInactivityTimer()
        }
    }
    
    @objc private func cursorPositionUpdate() {
        // Обновляем позицию курсора при рисовании правой кнопкой мыши
        updatePositionToMouse()
    }
    
    @objc private func cursorGlowEnabledChanged() {
        // При изменении режима свечения нужно обновить размер окна
        if isRunning {
            // Сохраняем состояние режима карандаша
            let wasPencilMode = highlightView?.isPencilMode ?? false
            
            // Закрываем старое окно
            window?.orderOut(nil)
            window = nil
            highlightView = nil
            
            // Пересоздаём окно с новым размером
            createWindowIfNeeded()
            
            // Восстанавливаем режим карандаша, если он был активен
            if wasPencilMode {
                highlightView?.isPencilMode = true
                highlightView?.pencilModeColor = CursorSettings.shared.pencilColor.color
            }
            
            updatePositionToMouse()
        }
        
        // Обновляем трек при изменении режима glowing
        if CursorSettings.shared.cursorTrailEnabled {
            for trailWindow in trailWindows {
                trailWindow.contentView?.needsDisplay = true
            }
        }
    }
    
    @objc private func cursorTrailEnabledChanged() {
        if CursorSettings.shared.cursorTrailEnabled {
            // Если режим трека включен, создаем окна трека
            createTrailWindowsIfNeeded()
        } else {
            // Если режим трека выключен, очищаем и скрываем окна трека
            for trailWindow in trailWindows {
                trailWindow.clearTrails()
                trailWindow.endTrail()
            }
            trailWindows.removeAll()
        }
    }
    
    @objc private func inactivityTimeoutChanged() {
        // При изменении таймаута перезапускаем таймер, если он активен
        if CursorSettings.shared.hideWhenInactive {
            resetInactivityTimer()
        }
    }
    
    private func showPencilSettingsPanel() {
        // Создаем окно панели настроек, если его еще нет
        if pencilSettingsWindow == nil {
            createPencilSettingsWindow()
        }
        
        guard let pencilSettingsWindow = pencilSettingsWindow else { return }
        
        // Находим экран, на котором находится курсор
        let currentPos = NSEvent.mouseLocation
        var targetScreen = NSScreen.main
        
        for screen in NSScreen.screens {
            if screen.frame.contains(currentPos) {
                targetScreen = screen
                break
            }
        }
        
        guard let screen = targetScreen else { return }
        
        let screenFrame = screen.frame
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 250
        
        // Позиционируем в правом нижнем углу экрана
        let panelX = screenFrame.maxX - panelWidth - 20
        let panelY = screenFrame.minY + 20
        
        pencilSettingsWindow.setFrame(
            NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight),
            display: true
        )
        pencilSettingsWindow.orderFrontRegardless()
    }
    
    private func hidePencilSettingsPanel() {
        pencilSettingsWindow?.orderOut(nil)
    }
    
    private func createPencilSettingsWindow() {
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 250
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        
        let settingsView = PencilSettingsPanel(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        settingsView.wantsLayer = true
        
        panel.contentView = settingsView
        self.pencilSettingsWindow = panel
    }
    
    // MARK: - Trail Management
    
    private func createTrailWindowsIfNeeded() {
        // Если окна уже созданы, просто убеждаемся что они видимы
        if !trailWindows.isEmpty {
            for trailWindow in trailWindows {
                trailWindow.orderFrontRegardless()
            }
            return
        }
        
        // Получаем все экраны
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        // Создаем отдельное окно для каждого экрана
        for screen in screens {
            let screenFrame = screen.frame
            
            let window = TrailWindow(
                contentRect: screenFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            // Сохраняем frame экрана для преобразования координат
            window.screenFrame = screenFrame
            
            // Убеждаемся, что окно видимо
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            trailWindows.append(window)
        }
    }
    
    private func startTrail(at point: NSPoint) {
        createTrailWindowsIfNeeded()
        guard !trailWindows.isEmpty else { return }
        
        // Добавляем точку начала трека во все окна (точки хранятся в глобальных координатах)
        for trailWindow in trailWindows {
            trailWindow.startTrail(at: point)
        }
    }
    
    private func addTrailPoint(_ point: NSPoint) {
        guard !trailWindows.isEmpty else { return }
        
        // Добавляем точку трека во все окна (точки хранятся в глобальных координатах)
        for trailWindow in trailWindows {
            trailWindow.addTrailPoint(point)
        }
    }
    
    private func endTrail() {
        for trailWindow in trailWindows {
            trailWindow.endTrail()
        }
    }
}
