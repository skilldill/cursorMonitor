import SwiftUI
import Cocoa

struct SettingsView: View {
    @ObservedObject private var settings = CursorSettingsObservable()
    @State private var previewBaseColor: NSColor = CursorSettings.shared.color.color
    @State private var previewClickColor: NSColor = CursorSettings.shared.clickColor.color
    @State private var previewOpacity: CGFloat = CursorSettings.shared.opacity
    @State private var previewSize: CGFloat = CursorSettings.shared.size.diameter
    @State private var notificationObservers: [NSObjectProtocol] = []
    @State private var currentLanguage: AppLanguage = Localization.shared.currentLanguage
    
    // Вычисляет размер превью с учетом тени (если включен режим свечения)
    private func calculatePreviewSize() -> CGFloat {
        let baseSize = CursorSettings.shared.size.diameter
        if CursorSettings.shared.cursorGlowEnabled {
            // Радиус размытия тени = outerLineWidth * 2.5
            let blurRadius = CursorSettings.shared.outerLineWidth * 2.5
            // Добавляем тень с каждой стороны (blurRadius * 2) + дополнительный запас для безопасности
            let padding: CGFloat = blurRadius * 2 + 20
            return baseSize + padding
        }
        return baseSize
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Cursor Settings Section
                cursorSettingsSection
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                
                // Trailing Settings Section
                trailingSection
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                
                // Language Section
                languageSection
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                
                // Reset Button
                resetButton
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Apply Button
                applyButton
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.15, green: 0.18, blue: 0.22))
        .id(currentLanguage) // Пересоздаем весь view при изменении языка
        .onAppear {
            setupNotifications()
            currentLanguage = Localization.shared.currentLanguage
        }
        .onDisappear {
            removeNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            currentLanguage = Localization.shared.currentLanguage
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("settings.preview"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(settings.textColor)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .frame(height: 200)
                
                HighlightViewRepresentable(
                    baseColor: previewBaseColor,
                    clickColor: previewClickColor,
                    opacity: previewOpacity,
                    size: calculatePreviewSize()
                )
                .frame(width: calculatePreviewSize(), height: calculatePreviewSize())
                .id("\(previewSize)-\(CursorSettings.shared.cursorGlowEnabled)") // Force update on size or glow change
            }
        }
        .onAppear {
            previewBaseColor = CursorSettings.shared.color.color
            previewClickColor = CursorSettings.shared.clickColor.color
            previewOpacity = CursorSettings.shared.opacity
            previewSize = CursorSettings.shared.size.diameter
        }
    }
    
    // MARK: - Cursor Settings Section
    private var cursorSettingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(L("settings.cursorSettings"))
            
            VStack(spacing: 16) {
                SettingRow(label: L("settings.cursorColor")) {
                    ColorPickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.color },
                            set: { CursorSettings.shared.color = $0 }
                        ),
                        onSelectionChange: { color in
                            CursorSettings.shared.color = color
                        }
                    )
                }
                
                SettingRow(label: L("settings.clickColor")) {
                    ColorPickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.clickColor },
                            set: { CursorSettings.shared.clickColor = $0 }
                        ),
                        onSelectionChange: { color in
                            CursorSettings.shared.clickColor = color
                        }
                    )
                }
                
                SettingRow(label: L("settings.cursorSize")) {
                    SizePickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.size },
                            set: { CursorSettings.shared.size = $0 }
                        )
                    )
                }
                
                SettingRow(label: L("settings.cursorShape")) {
                    ShapePickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.shape },
                            set: { CursorSettings.shared.shape = $0 }
                        )
                    )
                }
                
                SettingRow(label: L("settings.innerGlowStyle")) {
                    InnerGlowStylePickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.innerGlowStyle },
                            set: { CursorSettings.shared.innerGlowStyle = $0 }
                        )
                    )
                }
                
                SettingRow(label: L("settings.outerLineWidth")) {
                    HStack(spacing: 12) {
                        CustomSlider(
                            value: Binding(
                                get: { Double(CursorSettings.shared.outerLineWidth) },
                                set: { CursorSettings.shared.outerLineWidth = CGFloat($0) }
                            ),
                            in: 1...10,
                            step: 0.1
                        )
                        
                        Text(String(format: "%.1f", CursorSettings.shared.outerLineWidth))
                            .frame(width: 50, alignment: .trailing)
                            .foregroundColor(settings.textColor)
                            .monospacedDigit()
                    }
                }
                
                SettingRow(label: L("settings.transparency")) {
                    HStack(spacing: 12) {
                        CustomSlider(
                            value: Binding(
                                get: { Double(CursorSettings.shared.opacity) },
                                set: { CursorSettings.shared.opacity = CGFloat($0) }
                            ),
                            in: 0.1...1.0,
                            step: 0.01
                        )
                        
                        Text("\(Int(CursorSettings.shared.opacity * 100))%")
                            .frame(width: 50, alignment: .trailing)
                            .foregroundColor(settings.textColor)
                            .monospacedDigit()
                    }
                }
                
                SettingRow(label: L("settings.shadowBrightness")) {
                    HStack(spacing: 12) {
                        CustomSlider(
                            value: Binding(
                                get: { Double(CursorSettings.shared.shadowBrightness) },
                                set: { CursorSettings.shared.shadowBrightness = CGFloat($0) }
                            ),
                            in: 0...1.0,
                            step: 0.01
                        )
                        
                        Text("\(Int(CursorSettings.shared.shadowBrightness * 100))%")
                            .frame(width: 50, alignment: .trailing)
                            .foregroundColor(settings.textColor)
                            .monospacedDigit()
                    }
                }
                
                SettingRow(label: L("settings.hideWhenInactive")) {
                    Toggle("", isOn: Binding(
                        get: { CursorSettings.shared.hideWhenInactive },
                        set: { CursorSettings.shared.hideWhenInactive = $0 }
                    ))
                    .toggleStyle(.switch)
                }
                
                if CursorSettings.shared.hideWhenInactive {
                    SettingRow(label: L("settings.inactivityTimeout")) {
                        HStack(spacing: 12) {
                            CustomSlider(
                                value: Binding(
                                    get: { Double(CursorSettings.shared.inactivityTimeout) },
                                    set: { CursorSettings.shared.inactivityTimeout = $0 }
                                ),
                                in: 0.5...10.0,
                                step: 0.1
                            )
                            
                            Text(String(format: "%.1f s", CursorSettings.shared.inactivityTimeout))
                                .frame(width: 60, alignment: .trailing)
                                .foregroundColor(settings.textColor)
                                .monospacedDigit()
                        }
                    }
                }
                
                SettingRow(label: L("settings.glowEffect")) {
                    Toggle("", isOn: Binding(
                        get: { CursorSettings.shared.cursorGlowEnabled },
                        set: { CursorSettings.shared.cursorGlowEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                }
                
                SettingRow(label: L("settings.gradientColor")) {
                    Toggle("", isOn: Binding(
                        get: { CursorSettings.shared.cursorGradientEnabled },
                        set: { CursorSettings.shared.cursorGradientEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                    .disabled(CursorSettings.shared.cursorGlowEnabled) // Отключаем если включен режим свечения
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
            )
        }
    }
    
    private var trailingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(L("settings.trailSettings"))

            VStack(spacing: 16) {
                SettingRow(label: L("settings.leaveTrail")) {
                        Toggle("", isOn: Binding(
                            get: { CursorSettings.shared.cursorTrailEnabled },
                            set: { CursorSettings.shared.cursorTrailEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    if CursorSettings.shared.cursorTrailEnabled {
                        SettingRow(label: L("settings.trailLineWidth")) {
                            HStack {
                                Slider(
                                    value: Binding(
                                        get: { CursorSettings.shared.trailLineWidth },
                                        set: { CursorSettings.shared.trailLineWidth = $0 }
                                    ),
                                    in: 1...20,
                                    step: 0.5
                                )
                                Text(String(format: "%.1f", CursorSettings.shared.trailLineWidth))
                                    .frame(width: 40)
                                    .foregroundColor(settings.textColor)
                            }
                        }
                        
                        SettingRow(label: L("settings.trailFadeDuration")) {
                            HStack {
                                Stepper(
                                    value: Binding(
                                        get: { CursorSettings.shared.trailFadeDurationMs },
                                        set: { CursorSettings.shared.trailFadeDurationMs = $0 }
                                    ),
                                    in: 100...2000,
                                    step: 100
                                ) {
                                    Text("\(CursorSettings.shared.trailFadeDurationMs) ms")
                                        .frame(width: 80, alignment: .trailing)
                                        .foregroundColor(settings.textColor)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                )
            }
    }

    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(L("settings.language"))
            
            VStack(spacing: 16) {
                SettingRow(label: L("settings.language")) {
                    Picker("", selection: Binding(
                        get: { Localization.shared.currentLanguage },
                        set: { Localization.shared.currentLanguage = $0 }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 320)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
            )
        }
    }
    
    // MARK: - Reset Button
    private var resetButton: some View {
        Button(L("settings.resetDefaults")) {
            let alert = NSAlert()
            alert.messageText = L("settings.resetDefaultsConfirm")
            alert.informativeText = L("settings.resetDefaultsWarning")
            alert.addButton(withTitle: L("settings.reset"))
            alert.addButton(withTitle: L("note.cancel"))
            alert.alertStyle = .warning
            
            if alert.runModal() == .alertFirstButtonReturn {
                CursorSettings.shared.resetToDefaults()
                // Обновляем preview
                previewBaseColor = CursorSettings.shared.color.color
                previewClickColor = CursorSettings.shared.clickColor.color
                previewOpacity = CursorSettings.shared.opacity
                previewSize = CursorSettings.shared.size.diameter
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
    }
    
    // MARK: - Apply Button
    private var applyButton: some View {
        Button(L("settings.apply")) {
            // Close window
            NSApplication.shared.keyWindow?.close()
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.return, modifiers: [])
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 20)
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(settings.textColor)
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        let observer1 = NotificationCenter.default.addObserver(
            forName: .cursorColorChanged,
            object: nil,
            queue: .main
        ) { _ in
            previewBaseColor = CursorSettings.shared.color.color
            settings.objectWillChange.send()
        }
        
        let observer2 = NotificationCenter.default.addObserver(
            forName: .cursorSizeChanged,
            object: nil,
            queue: .main
        ) { _ in
            previewSize = CursorSettings.shared.size.diameter
            settings.objectWillChange.send()
        }
        
        let observer3 = NotificationCenter.default.addObserver(
            forName: .cursorShapeChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer4 = NotificationCenter.default.addObserver(
            forName: .cursorOpacityChanged,
            object: nil,
            queue: .main
        ) { _ in
            previewOpacity = CursorSettings.shared.opacity
            settings.objectWillChange.send()
        }
        
        let observer5 = NotificationCenter.default.addObserver(
            forName: .innerGlowStyleChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer6 = NotificationCenter.default.addObserver(
            forName: .outerLineWidthChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer7 = NotificationCenter.default.addObserver(
            forName: .cursorClickColorChanged,
            object: nil,
            queue: .main
        ) { _ in
            previewClickColor = CursorSettings.shared.clickColor.color
            settings.objectWillChange.send()
        }
        
        let observer8 = NotificationCenter.default.addObserver(
            forName: .cursorShadowBrightnessChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer9 = NotificationCenter.default.addObserver(
            forName: .appThemeChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer10 = NotificationCenter.default.addObserver(
            forName: .cursorGlowEnabledChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer11 = NotificationCenter.default.addObserver(
            forName: .outerLineWidthChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer12 = NotificationCenter.default.addObserver(
            forName: .cursorGradientEnabledChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer13 = NotificationCenter.default.addObserver(
            forName: .cursorTrailEnabledChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer14 = NotificationCenter.default.addObserver(
            forName: .trailLineWidthChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer15 = NotificationCenter.default.addObserver(
            forName: .trailFadeDurationChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer16 = NotificationCenter.default.addObserver(
            forName: .languageChanged,
            object: nil,
            queue: .main
        ) { _ in
            currentLanguage = Localization.shared.currentLanguage
            settings.objectWillChange.send()
        }
        
        let observer17 = NotificationCenter.default.addObserver(
            forName: .hideWhenInactiveChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        let observer18 = NotificationCenter.default.addObserver(
            forName: .inactivityTimeoutChanged,
            object: nil,
            queue: .main
        ) { _ in
            settings.objectWillChange.send()
        }
        
        notificationObservers = [observer1, observer2, observer3, observer4, observer5, observer6, observer7, observer8, observer9, observer10, observer11, observer12, observer13, observer14, observer15, observer16, observer17, observer18]
    }
    
    private func removeNotifications() {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
    }
}

// MARK: - Setting Row
struct SettingRow<Content: View>: View {
    let label: String
    let content: Content
    @ObservedObject private var settings = CursorSettingsObservable()
    @State private var languageUpdateTrigger = UUID()
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(label)
                .frame(width: 180, alignment: .leading)
                .foregroundColor(settings.textColor)
                .id(languageUpdateTrigger)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 35)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            languageUpdateTrigger = UUID()
        }
    }
}

// MARK: - Color Picker View
struct ColorPickerView: View {
    @Binding var selection: CursorColor
    let onSelectionChange: ((CursorColor) -> Void)?
    @State private var languageUpdateTrigger = UUID()
    
    init(selection: Binding<CursorColor>, onSelectionChange: ((CursorColor) -> Void)? = nil) {
        self._selection = selection
        self.onSelectionChange = onSelectionChange
    }
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CursorColor.allCases, id: \.self) { color in
                HStack {
                    Circle()
                        .fill(Color(nsColor: color.color))
                        .frame(width: 12, height: 12)
                    Text(color.displayName)
                }
                .tag(color)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .id(languageUpdateTrigger)
        .onChange(of: selection) { newValue in
            onSelectionChange?(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            languageUpdateTrigger = UUID()
        }
    }
}

// MARK: - Size Picker View
struct SizePickerView: View {
    @Binding var selection: CursorSize
    @State private var languageUpdateTrigger = UUID()
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CursorSize.allCases, id: \.self) { size in
                Text(size.displayName).tag(size)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .id(languageUpdateTrigger)
        .onChange(of: selection) { _ in
            CursorSettings.shared.size = selection
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            languageUpdateTrigger = UUID()
        }
    }
}

// MARK: - Shape Picker View
struct ShapePickerView: View {
    @Binding var selection: CursorShape
    @State private var languageUpdateTrigger = UUID()
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CursorShape.allCases, id: \.self) { shape in
                Text(shape.displayName).tag(shape)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .id(languageUpdateTrigger)
        .onChange(of: selection) { _ in
            CursorSettings.shared.shape = selection
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            languageUpdateTrigger = UUID()
        }
    }
}

// MARK: - Inner Glow Style Picker View
struct InnerGlowStylePickerView: View {
    @Binding var selection: InnerGlowStyle
    @State private var languageUpdateTrigger = UUID()
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(InnerGlowStyle.allCases, id: \.self) { style in
                Text(style.displayName).tag(style)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .id(languageUpdateTrigger)
        .onChange(of: selection) { _ in
            CursorSettings.shared.innerGlowStyle = selection
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            languageUpdateTrigger = UUID()
        }
    }
}


// MARK: - Custom Slider (Solid Line)
struct CustomSlider: NSViewRepresentable {
    @Binding var value: Double
    let `in`: ClosedRange<Double>
    let step: Double
    
    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider()
        slider.minValue = `in`.lowerBound
        slider.maxValue = `in`.upperBound
        slider.doubleValue = value
        slider.allowsTickMarkValuesOnly = false
        slider.numberOfTickMarks = 0  // Убираем tick marks
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        return slider
    }
    
    func updateNSView(_ nsView: NSSlider, context: Context) {
        nsView.doubleValue = value
        context.coordinator.value = $value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }
    
    class Coordinator: NSObject {
        var value: Binding<Double>
        
        init(value: Binding<Double>) {
            self.value = value
        }
        
        @objc func valueChanged(_ sender: NSSlider) {
            value.wrappedValue = sender.doubleValue
        }
    }
}

// MARK: - Highlight View Representable
struct HighlightViewRepresentable: NSViewRepresentable {
    let baseColor: NSColor
    let clickColor: NSColor
    let opacity: CGFloat
    let size: CGFloat
    
    func makeNSView(context: Context) -> HighlightView {
        let view = HighlightView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.wantsLayer = true
        view.layer?.masksToBounds = false // Отключаем обрезку для тени
        view.baseColor = baseColor
        view.clickColor = clickColor
        view.opacity = opacity
        
        view.onClick = {
            view.beginClick()
        }
        
        view.onMouseUp = {
            view.endClick()
        }
        
        return view
    }
    
    func updateNSView(_ nsView: HighlightView, context: Context) {
        nsView.baseColor = baseColor
        nsView.clickColor = clickColor
        nsView.opacity = opacity
        
        // Используем переданный размер (уже с учетом тени)
        if nsView.frame.width != size || nsView.frame.height != size {
            nsView.frame = NSRect(x: 0, y: 0, width: size, height: size)
        }
        
        nsView.needsDisplay = true
    }
}

// MARK: - Observable Settings
class CursorSettingsObservable: ObservableObject {
    @Published var isDark: Bool {
        didSet {
            if isDark != CursorSettings.shared.menuTheme.isDark {
                CursorSettings.shared.menuTheme = isDark ? .dark : .light
            }
        }
    }
    
    var textColor: Color {
        .primary
    }
    
    var previewSize: CGFloat {
        CursorSettings.shared.size.diameter
    }
    
    init() {
        self.isDark = CursorSettings.shared.menuTheme == .dark
        
        NotificationCenter.default.addObserver(
            forName: .appThemeChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isDark = CursorSettings.shared.menuTheme == .dark
        }
    }
}

extension MenuTheme {
    var isDark: Bool {
        self == .dark
    }
}

extension NSColor {
    var color: Color {
        Color(nsColor: self)
    }
}

