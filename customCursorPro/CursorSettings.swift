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

class CursorSettings {
    static let shared = CursorSettings()
    
    private let colorKey = "cursorColor"
    private let sizeKey = "cursorSize"
    private let opacityKey = "cursorOpacity"
    private let clickColorKey = "cursorClickColor"
    
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
    
    private init() {}
}

extension Notification.Name {
    static let cursorColorChanged = Notification.Name("cursorColorChanged")
    static let cursorSizeChanged = Notification.Name("cursorSizeChanged")
    static let cursorOpacityChanged = Notification.Name("cursorOpacityChanged")
    static let cursorClickColorChanged = Notification.Name("cursorClickColorChanged")
}

