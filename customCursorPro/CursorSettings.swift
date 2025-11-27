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
    case xs = "xs"
    case s = "s"
    case m = "m"
    case l = "l"
    case xl = "xl"
    case xxl = "xxl"
    case xxxl = "xxxl"
    
    var displayName: String {
        switch self {
        case .xs: return "XS"
        case .s: return "S"
        case .m: return "M"
        case .l: return "L"
        case .xl: return "XL"
        case .xxl: return "XXL"
        case .xxxl: return "XXXL"
        }
    }
    
    var diameter: CGFloat {
        switch self {
        case .xs: return 50
        case .s: return 70  // Текущий маленький
        case .m: return 90  // Текущий средний
        case .l: return 110 // Текущий большой
        case .xl: return 130
        case .xxl: return 150
        case .xxxl: return 170
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
    private let pencilGlowEnabledKey = "pencilGlowEnabled"
    private let menuThemeKey = "menuTheme"
    private let cursorShapeKey = "cursorShape"
    private let innerGlowStyleKey = "innerGlowStyle"
    private let outerLineWidthKey = "outerLineWidth"
    private let shadowColorKey = "cursorShadowColor"
    private let shadowBrightnessKey = "cursorShadowBrightness"
    
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
            // Если сохранен старый размер, конвертируем его в новый
            if let oldRawValue = UserDefaults.standard.string(forKey: sizeKey) {
                switch oldRawValue {
                case "small": return .s
                case "medium": return .m
                case "large": return .l
                default: break
                }
            }
            return .m // По умолчанию средний (M)
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
    
    var pencilGlowEnabled: Bool {
        get {
            // Проверяем, установлено ли значение (по умолчанию false - старый режим)
            if UserDefaults.standard.object(forKey: pencilGlowEnabledKey) != nil {
                return UserDefaults.standard.bool(forKey: pencilGlowEnabledKey)
            }
            return false // По умолчанию выключено (старый режим)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: pencilGlowEnabledKey)
            NotificationCenter.default.post(name: .pencilGlowEnabledChanged, object: nil)
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
    
    // Цвет тени (опционально, по умолчанию используется основной цвет)
    var shadowColor: CursorColor? {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: shadowColorKey),
               let color = CursorColor(rawValue: rawValue) {
                return color
            }
            return nil // По умолчанию nil - используется основной цвет
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: shadowColorKey)
            } else {
                UserDefaults.standard.removeObject(forKey: shadowColorKey)
            }
            NotificationCenter.default.post(name: .cursorShadowColorChanged, object: nil)
        }
    }
    
    // Возвращает цвет тени (либо установленный отдельно, либо основной цвет)
    var effectiveShadowColor: CursorColor {
        return shadowColor ?? color
    }
    
    var shadowBrightness: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: shadowBrightnessKey)
            if value > 0 {
                return value
            }
            return 0.4 // По умолчанию 40% яркости тени
        }
        set {
            UserDefaults.standard.set(newValue, forKey: shadowBrightnessKey)
            NotificationCenter.default.post(name: .cursorShadowBrightnessChanged, object: nil)
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
    static let pencilGlowEnabledChanged = Notification.Name("pencilGlowEnabledChanged")
    static let menuThemeChanged = Notification.Name("menuThemeChanged")
    static let appThemeChanged = Notification.Name("appThemeChanged")
    static let innerGlowStyleChanged = Notification.Name("innerGlowStyleChanged")
    static let outerLineWidthChanged = Notification.Name("outerLineWidthChanged")
    static let cursorShadowColorChanged = Notification.Name("cursorShadowColorChanged")
    static let cursorShadowBrightnessChanged = Notification.Name("cursorShadowBrightnessChanged")
}

