import Cocoa

final class CursorHighlighter {

    private var window: NSWindow?
    private var highlightView: HighlightView?
    private var menuWindow: NSWindow?
    private var menuView: MenuView?
    private var noteInputWindow: NoteInputWindow?
    private var notesViewWindow: NotesViewWindow?
    private var drawingWindow: DrawingWindow?
    private var mouseMoveMonitor: Any?
    private var clickDownMonitor: Any?
    private var clickUpMonitor: Any?
    private var middleButtonMonitor: Any?
    private var keyDownMonitor: Any?

    private var diameter: CGFloat {
        return CursorSettings.shared.size.diameter
    }
    
    // Заморозка курсора
    private var isFrozen = false
    private var frozenPosition: NSPoint?
    
    // Скрытие курсора при вводе текста
    private var isHiddenForTextInput = false
    
    // Позиция для меню (справа от курсора)
    private let menuOffset: CGFloat = 20

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
    }
    
    @objc private func sizeChanged() {
        // Пересоздаём окно с новым размером
        if isRunning {
            // Закрываем старое окно
            window?.orderOut(nil)
            window = nil
            highlightView = nil
            
            // Пересоздаём окно с новым размером
            createWindowIfNeeded()
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        createWindowIfNeeded()
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
        if let monitor = middleButtonMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }

        mouseMoveMonitor = nil
        clickDownMonitor = nil
        clickUpMonitor = nil
        middleButtonMonitor = nil
        keyDownMonitor = nil

        window?.orderOut(nil)
        menuWindow?.orderOut(nil)
        drawingWindow?.stopDrawing()
        
        // Сброс состояния
        isFrozen = false
        frozenPosition = nil
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
        let initialRect = NSRect(
            x: screenFrame.midX - diameter / 2,
            y: screenFrame.midY - diameter / 2,
            width: diameter,
            height: diameter
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

        // Уровень поверх всего
        panel.level = .screenSaver

        // Поведение в Spaces / full screen
        panel.collectionBehavior = [
            .canJoinAllSpaces,    // есть во всех рабочих столах и полноэкранных спейсах
            .fullScreenAuxiliary, // может показываться вместе с fullscreen окнами
            .ignoresCycle         // не мешает cmd+`
        ]

        let view = HighlightView(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter))
        view.wantsLayer = true
        view.baseColor = CursorSettings.shared.color.color
        view.clickColor = CursorSettings.shared.clickColor.color
        view.opacity = CursorSettings.shared.opacity

        panel.contentView = view
        panel.orderFrontRegardless()

        self.window = panel
        self.highlightView = view
    }


    private func startMonitoring() {
        // Двигаем за мышью по всем экранам
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            // Показываем курсор при движении мыши, если он был скрыт для ввода текста
            self?.updatePositionToMouse()
        }

        // Левая кнопка мыши: mouseDown (для визуального эффекта)
        clickDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [weak self] _ in
            self?.highlightView?.beginClick()
        }

        // Левая кнопка мыши: mouseUp (для визуального эффекта)
        clickUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseUp]
        ) { [weak self] _ in
            self?.highlightView?.endClick()
        }
        
        // Колесико мыши (средняя кнопка): нажатие для открытия меню или отключения карандаша
        middleButtonMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.otherMouseDown]
        ) { [weak self] event in
            guard let self = self else { return }
            // Проверяем, что это именно колесико (buttonNumber == 2)
            if event.buttonNumber == 2 {
                // Если карандаш включен, отключаем его
                if self.drawingWindow?.isDrawing == true {
                    self.stopPencil()
                } else {
                    // Иначе открываем меню
                    self.showMenu()
                }
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
        
        // Позиционируем меню справа от курсора
        let menuWidth: CGFloat = 200
        let menuHeight: CGFloat = 200
        
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
            
            // Проверяем, не выходит ли меню за правый край экрана
            if menuX + menuWidth > screenFrame.maxX {
                // Если выходит, показываем слева от курсора
                menuX = currentPos.x - menuWidth - menuOffset
            }
            
            // Проверяем, не выходит ли меню за левый край экрана
            if menuX < screenFrame.minX {
                menuX = screenFrame.minX + 10
            }
            
            // Проверяем, не выходит ли меню за верхний край экрана
            if menuY + menuHeight > screenFrame.maxY {
                menuY = screenFrame.maxY - menuHeight - 10
            }
            
            // Проверяем, не выходит ли меню за нижний край экрана
            if menuY < screenFrame.minY {
                menuY = screenFrame.minY + 10
            }
        }
        
        menuWindow.setFrame(
            NSRect(x: menuX, y: menuY, width: menuWidth, height: menuHeight),
            display: true
        )
        menuWindow.orderFrontRegardless()
    }
    
    private func hideMenu() {
        menuWindow?.orderOut(nil)
    }
    
    private func createMenuWindow() {
        let menuWidth: CGFloat = 200
        let menuHeight: CGFloat = 240
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: menuWidth, height: menuHeight),
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
        
        let menuView = MenuView(frame: NSRect(x: 0, y: 0, width: menuWidth, height: menuHeight))
        menuView.wantsLayer = true
        
        // Устанавливаем обработчики для кнопок меню
        menuView.onSafariClick = { [weak self] in
            self?.openSafari()
        }
        menuView.onViewNotesClick = { [weak self] in
            self?.showNotesViewWindow()
        }
        menuView.onCalculatorClick = { [weak self] in
            self?.openCalculator()
        }
        menuView.onCreateNote = { [weak self] in
            self?.showNoteInputWindow()
        }
        menuView.onPencilClick = { [weak self] in
            self?.startPencil()
        }
        menuView.onClose = { [weak self] in
            self?.hideMenu()
        }
        
        panel.contentView = menuView
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
        print("Заметка обновлена: \(text)")
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
        print("Заметка сохранена: \(text)")
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
        // Скрываем курсор
        window?.orderOut(nil)
        // Запускаем рисование
        drawingWindow?.startDrawing()
        hideMenu()
    }
    
    private func stopPencil() {
        // Выключаем карандаш
        drawingWindow?.stopDrawing()
        // Показываем курсор снова
        if isRunning {
            window?.orderFrontRegardless()
        }
        hideMenu()
    }

    // Позиционирование окна по глобальным координатам мыши
    private func updatePositionToMouse() {
        guard let window = window, !isHiddenForTextInput else { return }

        // Глобальные координаты курсора (одна система для всех мониторов)
        let location = NSEvent.mouseLocation

        let newOrigin = NSPoint(
            x: location.x - diameter / 2,
            y: location.y - diameter / 2
        )

        window.setFrameOrigin(newOrigin)
        window.orderFrontRegardless()
    }
}
