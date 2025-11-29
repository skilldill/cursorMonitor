import Foundation

enum AppLanguage: String, CaseIterable {
    case russian = "ru"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
}

class Localization {
    static let shared = Localization()
    
    private let languageKey = "appLanguage"
    
    var currentLanguage: AppLanguage {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: languageKey),
               let language = AppLanguage(rawValue: rawValue) {
                return language
            }
            // По умолчанию английский
            return .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    private var strings: [String: [String: String]] = [:]
    
    private init() {
        loadStrings()
    }
    
    private func loadStrings() {
        strings = [
            "ru": [
                // AppDelegate
                "menu.toggleHighlight": "Переключить подсветку",
                "menu.keyboardShortcuts": "Горячие клавиши...",
                "menu.settings": "Настройки...",
                "menu.quit": "Выход",
                
                // NoteInputWindow
                "note.create": "Создать заметку",
                "note.edit": "Редактировать заметку",
                "note.save": "Сохранить",
                "note.cancel": "Отмена",
                
                // NotesViewWindow
                "notes.title": "Мои заметки",
                "notes.clearAll": "Очистить все",
                "notes.clearAllConfirm": "Очистить все заметки?",
                "notes.clearAllWarning": "Это действие нельзя отменить.",
                "notes.clear": "Очистить",
                
                // SettingsWindow
                "settings.title": "Настройки Cursor Pro",
                
                // SettingsView
                "settings.preview": "Предпросмотр",
                "settings.cursorSettings": "Настройки курсора",
                "settings.trailSettings": "Настройки следа",
                "settings.cursorColor": "Цвет курсора:",
                "settings.clickColor": "Цвет клика:",
                "settings.cursorSize": "Размер курсора:",
                "settings.cursorShape": "Форма курсора:",
                "settings.innerGlowStyle": "Стиль внутреннего свечения:",
                "settings.outerLineWidth": "Ширина внешней линии:",
                "settings.transparency": "Прозрачность:",
                "settings.shadowBrightness": "Яркость тени:",
                "settings.hideWhenInactive": "Скрывать при неактивности:",
                "settings.glowEffect": "Эффект свечения:",
                "settings.gradientColor": "Градиентный цвет:",
                "settings.leaveTrail": "Оставлять след:",
                "settings.trailLineWidth": "Толщина линии следа:",
                "settings.trailFadeDuration": "Длительность затухания следа:",
                "settings.tip": "💡 Совет: ⌘ + Клик открывает меню и закрывает режим карандаша",
                "settings.apply": "Применить",
                "settings.resetDefaults": "Вернуть настройки по-умолчанию",
                "settings.resetDefaultsConfirm": "Сбросить все настройки к значениям по умолчанию?",
                "settings.resetDefaultsWarning": "Это действие сбросит все настройки, кроме языка.",
                "settings.reset": "Сбросить",
                "settings.language": "Язык:",
                
                // ShortcutsWindow
                "shortcuts.title": "Горячие клавиши",
                "shortcuts.openMenu": "Открыть меню",
                "shortcuts.openMenuDesc": "Открыть меню курсора",
                "shortcuts.closeMenu": "Закрыть меню",
                "shortcuts.closeMenuDesc": "Закрыть меню курсора",
                "shortcuts.moveMenu": "Переместить меню",
                "shortcuts.moveMenuDesc": "Перетащите меню для перемещения",
                "shortcuts.startPencil": "Запустить режим карандаша",
                "shortcuts.startPencilDesc": "Активировать режим рисования",
                "shortcuts.stopPencil": "Остановить режим карандаша",
                "shortcuts.stopPencilDesc": "Деактивировать режим рисования",
                
                // CursorSettings - Colors
                "color.indigo": "Индиго",
                "color.blue": "Синий",
                "color.purple": "Фиолетовый",
                "color.pink": "Розовый",
                "color.red": "Красный",
                "color.orange": "Оранжевый",
                "color.yellow": "Жёлтый",
                "color.green": "Зелёный",
                "color.cyan": "Голубой",
                "color.glowing": "Светящийся",
                
                // CursorSettings - Shapes
                "shape.squircle": "Скругленный квадрат",
                "shape.circle": "Круг",
                "shape.hexagon": "Шестиугольник",
                "shape.triangle": "Треугольник",
                "shape.rhombus": "Ромб",
                "shape.pentagon": "Пятиугольник",
                
                // CursorSettings - Inner Glow Styles
                "glow.solid": "Сплошная",
                "glow.segmented": "Сегментированная",
                "glow.thinSegmented": "Тонкая сегментированная",
                
                // CursorSettings - Menu Theme
                "theme.dark": "Тёмная",
                "theme.light": "Светлая",
                
                // PencilSettingsPanel
                "pencil.title": "Настройки карандаша",
                "pencil.color": "Цвет:",
                "pencil.thickness": "Толщина:",
                "pencil.opacity": "Прозрачность:",
                "pencil.glowLines": "Светящиеся линии"
            ],
            "en": [
                // AppDelegate
                "menu.toggleHighlight": "Toggle Highlight",
                "menu.keyboardShortcuts": "Keyboard Shortcuts...",
                "menu.settings": "Settings...",
                "menu.quit": "Quit",
                
                // NoteInputWindow
                "note.create": "Create Note",
                "note.edit": "Edit Note",
                "note.save": "Save",
                "note.cancel": "Cancel",
                
                // NotesViewWindow
                "notes.title": "My Notes",
                "notes.clearAll": "Clear All",
                "notes.clearAllConfirm": "Clear all notes?",
                "notes.clearAllWarning": "This action cannot be undone.",
                "notes.clear": "Clear",
                
                // SettingsWindow
                "settings.title": "Cursor Pro Settings",
                
                // SettingsView
                "settings.preview": "Preview",
                "settings.cursorSettings": "Cursor Settings",
                "settings.trailSettings": "Trail Settings",
                "settings.cursorColor": "Cursor Color:",
                "settings.clickColor": "Click Color:",
                "settings.cursorSize": "Cursor Size:",
                "settings.cursorShape": "Cursor Shape:",
                "settings.innerGlowStyle": "Inner Glow Style:",
                "settings.outerLineWidth": "Outer Line Width:",
                "settings.transparency": "Transparency:",
                "settings.shadowBrightness": "Shadow Brightness:",
                "settings.hideWhenInactive": "Hide When Inactive:",
                "settings.glowEffect": "Glow Effect:",
                "settings.gradientColor": "Gradient Color:",
                "settings.leaveTrail": "Leave Trail:",
                "settings.trailLineWidth": "Trail Line Width:",
                "settings.trailFadeDuration": "Trail Fade Duration:",
                "settings.tip": "💡 Tip: ⌘ + Click opens menu and closes pencil mode",
                "settings.apply": "Apply",
                "settings.resetDefaults": "Reset to Defaults",
                "settings.resetDefaultsConfirm": "Reset all settings to default values?",
                "settings.resetDefaultsWarning": "This will reset all settings except language.",
                "settings.reset": "Reset",
                "settings.language": "Language:",
                
                // ShortcutsWindow
                "shortcuts.title": "Keyboard Shortcuts",
                "shortcuts.openMenu": "Open Menu",
                "shortcuts.openMenuDesc": "Open the cursor menu",
                "shortcuts.closeMenu": "Close Menu",
                "shortcuts.closeMenuDesc": "Close the cursor menu",
                "shortcuts.moveMenu": "Move Menu",
                "shortcuts.moveMenuDesc": "Drag the menu to move it",
                "shortcuts.startPencil": "Start Pencil Mode",
                "shortcuts.startPencilDesc": "Activate drawing mode",
                "shortcuts.stopPencil": "Stop Pencil Mode",
                "shortcuts.stopPencilDesc": "Deactivate drawing mode",
                
                // CursorSettings - Colors
                "color.indigo": "Indigo",
                "color.blue": "Blue",
                "color.purple": "Purple",
                "color.pink": "Pink",
                "color.red": "Red",
                "color.orange": "Orange",
                "color.yellow": "Yellow",
                "color.green": "Green",
                "color.cyan": "Cyan",
                "color.glowing": "Glowing",
                
                // CursorSettings - Shapes
                "shape.squircle": "Squircle",
                "shape.circle": "Circle",
                "shape.hexagon": "Hexagon",
                "shape.triangle": "Triangle",
                "shape.rhombus": "Rhombus",
                "shape.pentagon": "Pentagon",
                
                // CursorSettings - Inner Glow Styles
                "glow.solid": "Solid",
                "glow.segmented": "Segmented",
                "glow.thinSegmented": "Thin Segmented",
                
                // CursorSettings - Menu Theme
                "theme.dark": "Dark",
                "theme.light": "Light",
                
                // PencilSettingsPanel
                "pencil.title": "Pencil Settings",
                "pencil.color": "Color:",
                "pencil.thickness": "Thickness:",
                "pencil.opacity": "Opacity:",
                "pencil.glowLines": "Glow Lines"
            ]
        ]
    }
    
    func string(forKey key: String) -> String {
        let lang = currentLanguage.rawValue
        return strings[lang]?[key] ?? strings["en"]?[key] ?? key
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// Удобная функция для получения локализованной строки
func L(_ key: String) -> String {
    return Localization.shared.string(forKey: key)
}

