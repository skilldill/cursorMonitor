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
    case glowing = "glowing"
    
    var displayName: String {
        switch self {
        case .indigo: return L("color.indigo")
        case .blue: return L("color.blue")
        case .purple: return L("color.purple")
        case .pink: return L("color.pink")
        case .red: return L("color.red")
        case .orange: return L("color.orange")
        case .yellow: return L("color.yellow")
        case .green: return L("color.green")
        case .cyan: return L("color.cyan")
        case .glowing: return L("color.glowing")
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
        case .glowing: return NSColor(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0) // Яркий неоновый циан
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
    case xxxxl = "xxxxl"
    
    var displayName: String {
        switch self {
        case .xs: return "XS"
        case .s: return "S"
        case .m: return "M"
        case .l: return "L"
        case .xl: return "XL"
        case .xxl: return "XXL"
        case .xxxl: return "XXXL"
        case .xxxxl: return "XXXXL"
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
        case .xxxxl: return 190
        }
    }
}

enum MenuTheme: String, CaseIterable {
    case dark = "dark"
    case light = "light"
    
    var displayName: String {
        switch self {
        case .dark: return L("theme.dark")
        case .light: return L("theme.light")
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
        case .squircle: return L("shape.squircle")
        case .circle: return L("shape.circle")
        case .hexagon: return L("shape.hexagon")
        case .triangle: return L("shape.triangle")
        case .rhombus: return L("shape.rhombus")
        case .pentagon: return L("shape.pentagon")
        }
    }
}

enum InnerGlowStyle: String, CaseIterable {
    case solid = "solid"
    case segmented = "segmented"
    case thinSegmented = "thinSegmented"
    
    var displayName: String {
        switch self {
        case .solid: return L("glow.solid")
        case .segmented: return L("glow.segmented")
        case .thinSegmented: return L("glow.thinSegmented")
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
    private let hideWhenInactiveKey = "hideWhenInactive"
    private let cursorGlowEnabledKey = "cursorGlowEnabled"
    private let cursorGradientEnabledKey = "cursorGradientEnabled"
    private let cursorTrailEnabledKey = "cursorTrailEnabled"
    private let trailLineWidthKey = "trailLineWidth"
    private let trailFadeDurationKey = "trailFadeDuration"
    private let inactivityTimeoutKey = "inactivityTimeout"
    
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
            return .l // По умолчанию большой (L)
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
            return 1.0 // По умолчанию 100% непрозрачности
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
    
    var hideWhenInactive: Bool {
        get {
            // Проверяем, установлено ли значение (по умолчанию false)
            if UserDefaults.standard.object(forKey: hideWhenInactiveKey) != nil {
                return UserDefaults.standard.bool(forKey: hideWhenInactiveKey)
            }
            return true // По умолчанию включено (исчезновение курсора со временем)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hideWhenInactiveKey)
            NotificationCenter.default.post(name: .hideWhenInactiveChanged, object: nil)
        }
    }
    
    var inactivityTimeout: TimeInterval {
        get {
            let value = UserDefaults.standard.double(forKey: inactivityTimeoutKey)
            if value > 0 {
                return value
            }
            return 0.5 // По умолчанию 0.5 секунды
        }
        set {
            UserDefaults.standard.set(newValue, forKey: inactivityTimeoutKey)
            NotificationCenter.default.post(name: .inactivityTimeoutChanged, object: nil)
        }
    }
    
    var cursorGlowEnabled: Bool {
        get {
            // Проверяем, установлено ли значение (по умолчанию false)
            if UserDefaults.standard.object(forKey: cursorGlowEnabledKey) != nil {
                return UserDefaults.standard.bool(forKey: cursorGlowEnabledKey)
            }
            return false // По умолчанию выключено
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cursorGlowEnabledKey)
            // Если включаем режим свечения, отключаем градиент
            if newValue && cursorGradientEnabled {
                cursorGradientEnabled = false
            }
            NotificationCenter.default.post(name: .cursorGlowEnabledChanged, object: nil)
        }
    }
    
    var cursorGradientEnabled: Bool {
        get {
            // Проверяем, установлено ли значение (по умолчанию false)
            if UserDefaults.standard.object(forKey: cursorGradientEnabledKey) != nil {
                return UserDefaults.standard.bool(forKey: cursorGradientEnabledKey)
            }
            return false // По умолчанию выключено
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cursorGradientEnabledKey)
            NotificationCenter.default.post(name: .cursorGradientEnabledChanged, object: nil)
        }
    }
    
    var cursorTrailEnabled: Bool {
        get {
            // Проверяем, установлено ли значение (по умолчанию false)
            if UserDefaults.standard.object(forKey: cursorTrailEnabledKey) != nil {
                return UserDefaults.standard.bool(forKey: cursorTrailEnabledKey)
            }
            return false // По умолчанию выключено
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cursorTrailEnabledKey)
            NotificationCenter.default.post(name: .cursorTrailEnabledChanged, object: nil)
        }
    }
    
    var trailLineWidth: CGFloat {
        get {
            // Проверяем, установлено ли значение
            if UserDefaults.standard.object(forKey: trailLineWidthKey) != nil {
                let value = UserDefaults.standard.double(forKey: trailLineWidthKey)
                if value > 0 {
                    return value
                }
            }
            // По умолчанию используем толщину внешней линии курсора
            return outerLineWidth
        }
        set {
            UserDefaults.standard.set(newValue, forKey: trailLineWidthKey)
            NotificationCenter.default.post(name: .trailLineWidthChanged, object: nil)
        }
    }
    
    var trailFadeDuration: TimeInterval {
        get {
            // Проверяем, установлено ли значение
            if UserDefaults.standard.object(forKey: trailFadeDurationKey) != nil {
                let value = UserDefaults.standard.double(forKey: trailFadeDurationKey)
                if value > 0 {
                    return value / 1000.0 // Конвертируем из миллисекунд в секунды
                }
            }
            return 0.5 // По умолчанию 500 мс (0.5 секунды)
        }
        set {
            UserDefaults.standard.set(newValue * 1000.0, forKey: trailFadeDurationKey) // Сохраняем в миллисекундах
            NotificationCenter.default.post(name: .trailFadeDurationChanged, object: nil)
        }
    }
    
    // Вспомогательное свойство для получения trailFadeDuration в миллисекундах
    var trailFadeDurationMs: Int {
        get {
            // Проверяем, установлено ли значение
            if UserDefaults.standard.object(forKey: trailFadeDurationKey) != nil {
                let value = UserDefaults.standard.double(forKey: trailFadeDurationKey)
                if value > 0 {
                    return Int(value)
                }
            }
            return 500 // По умолчанию 500 мс
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: trailFadeDurationKey) // Сохраняем в миллисекундах
            NotificationCenter.default.post(name: .trailFadeDurationChanged, object: nil)
        }
    }
    
    // Метод для сброса настроек к значениям по умолчанию (кроме языка)
    func resetToDefaults() {
        // Цвет курсора
        UserDefaults.standard.set(CursorColor.indigo.rawValue, forKey: colorKey)
        
        // Размер курсора
        UserDefaults.standard.set(CursorSize.l.rawValue, forKey: sizeKey)
        
        // Цвет клика
        UserDefaults.standard.set(CursorColor.green.rawValue, forKey: clickColorKey)
        
        // Прозрачность
        UserDefaults.standard.set(1.0, forKey: opacityKey)
        
        // Форма курсора
        UserDefaults.standard.set(CursorShape.rhombus.rawValue, forKey: cursorShapeKey)
        
        // Стиль внутреннего свечения
        UserDefaults.standard.set(InnerGlowStyle.solid.rawValue, forKey: innerGlowStyleKey)
        
        // Ширина внешней линии
        UserDefaults.standard.set(5.0, forKey: outerLineWidthKey)
        
        // Яркость тени
        UserDefaults.standard.set(0.4, forKey: shadowBrightnessKey)
        
        // Скрывать при неактивности
        UserDefaults.standard.set(true, forKey: hideWhenInactiveKey)
        
        // Таймаут неактивности
        UserDefaults.standard.set(0.5, forKey: inactivityTimeoutKey)
        
        // Эффект свечения
        UserDefaults.standard.set(false, forKey: cursorGlowEnabledKey)
        
        // Градиентный цвет
        UserDefaults.standard.set(false, forKey: cursorGradientEnabledKey)
        
        // След курсора
        UserDefaults.standard.set(false, forKey: cursorTrailEnabledKey)
        
        // Толщина линии следа (будет использовать outerLineWidth по умолчанию)
        UserDefaults.standard.removeObject(forKey: trailLineWidthKey)
        
        // Длительность затухания следа
        UserDefaults.standard.set(500.0, forKey: trailFadeDurationKey)
        
        // Настройки карандаша
        UserDefaults.standard.set(CursorColor.red.rawValue, forKey: pencilColorKey)
        UserDefaults.standard.set(3.0, forKey: pencilLineWidthKey)
        UserDefaults.standard.set(1.0, forKey: pencilOpacityKey)
        UserDefaults.standard.set(false, forKey: pencilGlowEnabledKey)
        
        // Отправляем уведомления об изменении всех настроек
        NotificationCenter.default.post(name: .cursorColorChanged, object: nil)
        NotificationCenter.default.post(name: .cursorSizeChanged, object: nil)
        NotificationCenter.default.post(name: .cursorClickColorChanged, object: nil)
        NotificationCenter.default.post(name: .cursorOpacityChanged, object: nil)
        NotificationCenter.default.post(name: .cursorShapeChanged, object: nil)
        NotificationCenter.default.post(name: .innerGlowStyleChanged, object: nil)
        NotificationCenter.default.post(name: .outerLineWidthChanged, object: nil)
        NotificationCenter.default.post(name: .cursorShadowBrightnessChanged, object: nil)
        NotificationCenter.default.post(name: .hideWhenInactiveChanged, object: nil)
        NotificationCenter.default.post(name: .inactivityTimeoutChanged, object: nil)
        NotificationCenter.default.post(name: .cursorGlowEnabledChanged, object: nil)
        NotificationCenter.default.post(name: .cursorGradientEnabledChanged, object: nil)
        NotificationCenter.default.post(name: .cursorTrailEnabledChanged, object: nil)
        NotificationCenter.default.post(name: .trailLineWidthChanged, object: nil)
        NotificationCenter.default.post(name: .trailFadeDurationChanged, object: nil)
        NotificationCenter.default.post(name: .pencilColorChanged, object: nil)
        NotificationCenter.default.post(name: .pencilLineWidthChanged, object: nil)
        NotificationCenter.default.post(name: .pencilOpacityChanged, object: nil)
        NotificationCenter.default.post(name: .pencilGlowEnabledChanged, object: nil)
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
    static let hideWhenInactiveChanged = Notification.Name("hideWhenInactiveChanged")
    static let cursorGlowEnabledChanged = Notification.Name("cursorGlowEnabledChanged")
    static let cursorGradientEnabledChanged = Notification.Name("cursorGradientEnabledChanged")
    static let cursorTrailEnabledChanged = Notification.Name("cursorTrailEnabledChanged")
    static let trailLineWidthChanged = Notification.Name("trailLineWidthChanged")
    static let trailFadeDurationChanged = Notification.Name("trailFadeDurationChanged")
    static let inactivityTimeoutChanged = Notification.Name("inactivityTimeoutChanged")
    static let cursorPositionUpdate = Notification.Name("cursorPositionUpdate")
}

