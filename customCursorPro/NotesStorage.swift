import Foundation

struct Note: Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
    }
    
    init(id: UUID, text: String, createdAt: Date) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

class NotesStorage {
    static let shared = NotesStorage()
    
    private let notesKey = "cursorNotes"
    private var notes: [Note] = []
    
    private init() {
        loadNotes()
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    func getAllNotes() -> [Note] {
        return notes.reversed() // Новые заметки сверху
    }
    
    func deleteNote(withId id: UUID) {
        notes.removeAll { $0.id == id }
        saveNotes()
    }
    
    func updateNote(withId id: UUID, newText: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            // Создаем новую заметку с тем же ID и датой создания, но новым текстом
            let oldNote = notes[index]
            let updatedNote = Note(id: oldNote.id, text: newText, createdAt: oldNote.createdAt)
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func getNote(withId id: UUID) -> Note? {
        return notes.first { $0.id == id }
    }
    
    func clearAllNotes() {
        notes.removeAll()
        saveNotes()
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
}

