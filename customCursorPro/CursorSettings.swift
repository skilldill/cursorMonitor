import Cocoa

enum CursorColor: String, CaseIterable {
    case indigo = "indigo"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case cyan = "cyan"
    
    var displayName: String {
        switch self {
        case .indigo: return "Индиго"
        case .blue: return "Синий"
        case .purple: return "Фиолетовый"
        case .pink: return "Розовый"
        case .red: return "Красный"
        case .orange: return "Оранжевый"
        case .yellow: return "Жёлтый"
        case .green: return "Зелёный"
        case .cyan: return "Голубой"
        }
    }
    
    var color: NSColor {
        switch self {
        case .indigo: return .systemIndigo
        case .blue: return .systemBlue
        case .purple: return .systemPurple
        case .pink: return NSColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0)
        case .red: return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .cyan: return NSColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        }
    }
}

enum CursorSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "Маленький"
        case .medium: return "Средний"
        case .large: return "Большой"
        }
    }
    
    var diameter: CGFloat {
        switch self {
        case .small: return 70
        case .medium: return 90
        case .large: return 110
        }
    }
}

enum MenuTheme: String, CaseIterable {
    case dark = "dark"
    case light = "light"
    
    var displayName: String {
        switch self {
        case .dark: return "Тёмная"
        case .light: return "Светлая"
        }
    }
}

enum CursorShape: String, CaseIterable {
    case squircle = "squircle"
    case circle = "circle"
    case hexagon = "hexagon"
    case triangle = "triangle"
    case rhombus = "rhombus"
    case pentagon = "pentagon"
    
    var displayName: String {
        switch self {
        case .squircle: return "Скругленный квадрат"
        case .circle: return "Круг"
        case .hexagon: return "Шестиугольник"
        case .triangle: return "Треугольник"
        case .rhombus: return "Ромб"
        case .pentagon: return "Пятиугольник"
        }
    }
}

enum InnerGlowStyle: String, CaseIterable {
    case solid = "solid"
    case segmented = "segmented"
    case thinSegmented = "thinSegmented"
    
    var displayName: String {
        switch self {
        case .solid: return "Сплошная"
        case .segmented: return "Сегментированная"
        case .thinSegmented: return "Тонкая сегментированная"
        }
    }
}

class CursorSettings {
    static let shared = CursorSettings()
    
    private let colorKey = "cursorColor"
    private let sizeKey = "cursorSize"
    private let opacityKey = "cursorOpacity"
    private let clickColorKey = "cursorClickColor"
    private let pencilColorKey = "pencilColor"
    private let pencilLineWidthKey = "pencilLineWidth"
    private let pencilOpacityKey = "pencilOpacity"
    private let menuThemeKey = "menuTheme"
    private let cursorShapeKey = "cursorShape"
    private let innerGlowStyleKey = "innerGlowStyle"
    private let outerLineWidthKey = "outerLineWidth"
    
    var menuTheme: MenuTheme {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: menuThemeKey),
               let theme = MenuTheme(rawValue: rawValue) {
                return theme
            }
            return .dark // По умолчанию тёмная тема
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: menuThemeKey)
            NotificationCenter.default.post(name: .menuThemeChanged, object: nil)
            NotificationCenter.default.post(name: .appThemeChanged, object: nil)
        }
    }
    
    // Общее переключение темы для всего приложения
    func toggleTheme() {
        menuTheme = menuTheme == .dark ? .light : .dark
    }
    
    var color: CursorColor {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: colorKey),
               let color = CursorColor(rawValue: rawValue) {
                return color
            }
            return .indigo // По умолчанию
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: colorKey)
            NotificationCenter.default.post(name: .cursorColorChanged, object: nil)
        }
    }
    
    var size: CursorSize {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: sizeKey),
               let size = CursorSize(rawValue: rawValue) {
                return size
            }
            return .medium // По умолчанию
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: sizeKey)
            NotificationCenter.default.post(name: .cursorSizeChanged, object: nil)
        }
    }
    
    var opacity: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: opacityKey)
            if value > 0 {
                return value
            }
            return 0.7 // По умолчанию 70% непрозрачности
        }
        set {
            UserDefaults.standard.set(newValue, forKey: opacityKey)
            NotificationCenter.default.post(name: .cursorOpacityChanged, object: nil)
        }
    }
    
    var clickColor: CursorColor {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: clickColorKey),
               let color = CursorColor(rawValue: rawValue) {
                return color
            }
            return .green // По умолчанию зелёный
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: clickColorKey)
            NotificationCenter.default.post(name: .cursorClickColorChanged, object: nil)
        }
    }
    
    var pencilColor: CursorColor {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: pencilColorKey),
               let color = CursorColor(rawValue: rawValue) {
                return color
            }
            return .red // По умолчанию красный
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: pencilColorKey)
            NotificationCenter.default.post(name: .pencilColorChanged, object: nil)
        }
    }
    
    var pencilLineWidth: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: pencilLineWidthKey)
            if value > 0 {
                return value
            }
            return 3.0 // По умолчанию 3.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: pencilLineWidthKey)
            NotificationCenter.default.post(name: .pencilLineWidthChanged, object: nil)
        }
    }
    
    var pencilOpacity: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: pencilOpacityKey)
            if value > 0 {
                return value
            }
            return 1.0 // По умолчанию 100% непрозрачности
        }
        set {
            UserDefaults.standard.set(newValue, forKey: pencilOpacityKey)
            NotificationCenter.default.post(name: .pencilOpacityChanged, object: nil)
        }
    }
    
    var shape: CursorShape {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: cursorShapeKey),
               let shape = CursorShape(rawValue: rawValue) {
                return shape
            }
            return .rhombus // По умолчанию ромб (текущая форма)
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: cursorShapeKey)
            NotificationCenter.default.post(name: .cursorShapeChanged, object: nil)
        }
    }
    
    var innerGlowStyle: InnerGlowStyle {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: innerGlowStyleKey),
               let style = InnerGlowStyle(rawValue: rawValue) {
                return style
            }
            return .solid // По умолчанию сплошная
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: innerGlowStyleKey)
            NotificationCenter.default.post(name: .innerGlowStyleChanged, object: nil)
        }
    }
    
    var outerLineWidth: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: outerLineWidthKey)
            if value > 0 {
                return value
            }
            return 5.0 // По умолчанию 5.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: outerLineWidthKey)
            NotificationCenter.default.post(name: .outerLineWidthChanged, object: nil)
        }
    }
    
    private init() {}
}

extension Notification.Name {
    static let cursorColorChanged = Notification.Name("cursorColorChanged")
    static let cursorSizeChanged = Notification.Name("cursorSizeChanged")
    static let cursorOpacityChanged = Notification.Name("cursorOpacityChanged")
    static let cursorClickColorChanged = Notification.Name("cursorClickColorChanged")
    static let cursorShapeChanged = Notification.Name("cursorShapeChanged")
    static let pencilColorChanged = Notification.Name("pencilColorChanged")
    static let pencilLineWidthChanged = Notification.Name("pencilLineWidthChanged")
    static let pencilOpacityChanged = Notification.Name("pencilOpacityChanged")
    static let menuThemeChanged = Notification.Name("menuThemeChanged")
    static let appThemeChanged = Notification.Name("appThemeChanged")
    static let innerGlowStyleChanged = Notification.Name("innerGlowStyleChanged")
    static let outerLineWidthChanged = Notification.Name("outerLineWidthChanged")
}

