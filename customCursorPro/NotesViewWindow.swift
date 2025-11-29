import Cocoa

class NotesViewWindow: NSWindowController {
    
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var clearButton: NSButton!
    private var notes: [Note] = []
    var onEditNote: ((Note) -> Void)?
    
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
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("notes.title")
        window.center()
        window.isReleasedWhenClosed = false
        
        // Предотвращаем сворачивание в боковую панель Stage Manager
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = window.contentView!
        
        // Таблица заметок
        scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: 400))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.allowsColumnResizing = false
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.doubleAction = #selector(doubleClickOnNote)
        tableView.target = self
        
        // Колонка для заметок
        let noteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("noteColumn"))
        noteColumn.width = 560
        tableView.addTableColumn(noteColumn)
        
        scrollView.documentView = tableView
        contentView.addSubview(scrollView)
        
        // Кнопка "Очистить все"
        clearButton = NSButton(frame: NSRect(x: 20, y: 20, width: 120, height: 32))
        clearButton.title = L("notes.clearAll")
        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearAllNotes)
        contentView.addSubview(clearButton)
        
        // Подписываемся на изменения языка
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
        
        self.window = window
        loadNotes()
    }
    
    @objc private func languageChanged() {
        // Обновляем тексты при изменении языка
        window?.title = L("notes.title")
        clearButton?.title = L("notes.clearAll")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func showWindow() {
        loadNotes()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func loadNotes() {
        notes = NotesStorage.shared.getAllNotes()
        tableView.reloadData()
    }
    
    @objc private func clearAllNotes() {
        let alert = NSAlert()
        alert.messageText = L("notes.clearAllConfirm")
        alert.informativeText = L("notes.clearAllWarning")
        alert.addButton(withTitle: L("notes.clear"))
        alert.addButton(withTitle: L("note.cancel"))
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            NotesStorage.shared.clearAllNotes()
            loadNotes()
        }
    }
}

extension NotesViewWindow: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < notes.count else { return nil }
        
        let note = notes[row]
        let cellIdentifier = NSUserInterfaceItemIdentifier("noteCell")
        
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NoteCellView
        if cell == nil {
            cell = NoteCellView(frame: NSRect(x: 0, y: 0, width: 560, height: 60))
            cell?.identifier = cellIdentifier
            cell?.deleteButton.target = self
            cell?.deleteButton.action = #selector(deleteNote(_:))
            cell?.editButton.target = self
            cell?.editButton.action = #selector(editNote(_:))
        }
        
        // Обновляем данные
        cell?.configure(with: note, row: row)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 60
    }
    
    @objc private func deleteNote(_ sender: NSButton) {
        guard let cellView = sender.superview as? NoteCellView,
              let noteId = cellView.noteId else { return }
        
        NotesStorage.shared.deleteNote(withId: noteId)
        loadNotes()
    }
    
    @objc private func editNote(_ sender: NSButton) {
        guard let cellView = sender.superview as? NoteCellView,
              let noteId = cellView.noteId,
              let note = NotesStorage.shared.getNote(withId: noteId) else { return }
        
        onEditNote?(note)
    }
    
    @objc private func doubleClickOnNote() {
        let row = tableView.clickedRow
        guard row >= 0 && row < notes.count else { return }
        
        let note = notes[row]
        onEditNote?(note)
    }
}

// Вспомогательный класс для ячейки заметки
class NoteCellView: NSTableCellView {
    var noteId: UUID?
    let noteTextField: NSTextField
    let dateField: NSTextField
    let deleteButton: NSButton
    let editButton: NSButton
    
    override init(frame frameRect: NSRect) {
        // Текст заметки
        noteTextField = NSTextField(frame: NSRect(x: 10, y: 30, width: 460, height: 20))
        noteTextField.isEditable = false
        noteTextField.isSelectable = true
        noteTextField.isBordered = false
        noteTextField.backgroundColor = .clear
        noteTextField.font = NSFont.systemFont(ofSize: 13)
        noteTextField.textColor = .labelColor
        noteTextField.lineBreakMode = .byTruncatingTail
        
        // Дата создания
        dateField = NSTextField(frame: NSRect(x: 10, y: 10, width: 500, height: 15))
        dateField.isEditable = false
        dateField.isSelectable = false
        dateField.isBordered = false
        dateField.backgroundColor = .clear
        dateField.font = NSFont.systemFont(ofSize: 11)
        dateField.textColor = .secondaryLabelColor
        
        // Кнопка удаления
        deleteButton = NSButton(frame: NSRect(x: 520, y: 15, width: 30, height: 30))
        deleteButton.title = "✕"
        deleteButton.bezelStyle = .rounded
        deleteButton.font = NSFont.systemFont(ofSize: 12)
        
        // Кнопка редактирования
        editButton = NSButton(frame: NSRect(x: 480, y: 15, width: 30, height: 30))
        editButton.title = "✎"
        editButton.bezelStyle = .rounded
        editButton.font = NSFont.systemFont(ofSize: 12)
        
        super.init(frame: frameRect)
        
        addSubview(noteTextField)
        addSubview(dateField)
        addSubview(deleteButton)
        addSubview(editButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with note: Note, row: Int) {
        noteId = note.id
        noteTextField.stringValue = note.text
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateField.stringValue = formatter.string(from: note.createdAt)
    }
}

