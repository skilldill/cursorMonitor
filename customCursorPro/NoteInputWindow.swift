import Cocoa

class NoteInputWindow: NSWindowController {
    
    private var textView: NSTextView!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!
    
    var onSave: ((String) -> Void)?
    var onUpdate: ((UUID, String) -> Void)?
    
    private var editingNoteId: UUID?
    
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Создать заметку"
        window.center()
        window.isReleasedWhenClosed = false
        
        // Предотвращаем сворачивание в боковую панель Stage Manager
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = window.contentView!
        
        // Текстовое поле (многострочное)
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 460, height: 200))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        textView = NSTextView(frame: scrollView.bounds)
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.string = ""
        
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        // Кнопка "Сохранить"
        saveButton = NSButton(frame: NSRect(x: 350, y: 20, width: 120, height: 32))
        saveButton.title = "Сохранить"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        saveButton.keyEquivalent = "\r" // Enter для сохранения
        contentView.addSubview(saveButton)
        
        // Кнопка "Отмена"
        cancelButton = NSButton(frame: NSRect(x: 220, y: 20, width: 120, height: 32))
        cancelButton.title = "Отмена"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonClicked)
        cancelButton.keyEquivalent = "\u{1b}" // Escape для отмены
        contentView.addSubview(cancelButton)
        
        // Устанавливаем делегат для обработки закрытия окна
        window.delegate = self
        
        self.window = window
        
        // Фокусируемся на текстовом поле при открытии
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self?.textView)
        }
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeFirstResponder(textView)
    }
    
    func showWindowForEditing(note: Note) {
        editingNoteId = note.id
        textView.string = note.text
        window?.title = "Редактировать заметку"
        showWindow()
    }
    
    func showWindowForCreating() {
        editingNoteId = nil
        textView.string = ""
        window?.title = "Создать заметку"
        showWindow()
    }
    
    @objc private func saveButtonClicked() {
        let text = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            if let noteId = editingNoteId {
                // Редактируем существующую заметку
                onUpdate?(noteId, text)
            } else {
                // Создаем новую заметку
                onSave?(text)
            }
            window?.close()
        }
    }
    
    @objc private func cancelButtonClicked() {
        window?.close()
    }
}

extension NoteInputWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Очищаем поле при закрытии
        textView.string = ""
        editingNoteId = nil
        window?.title = "Создать заметку"
    }
}

