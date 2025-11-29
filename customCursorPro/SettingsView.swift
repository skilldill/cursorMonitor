import SwiftUI
import Cocoa

struct SettingsView: View {
    @ObservedObject private var settings = CursorSettingsObservable()
    @State private var previewBaseColor: NSColor = CursorSettings.shared.color.color
    @State private var previewClickColor: NSColor = CursorSettings.shared.clickColor.color
    @State private var previewOpacity: CGFloat = CursorSettings.shared.opacity
    @State private var previewSize: CGFloat = CursorSettings.shared.size.diameter
    @State private var notificationObservers: [NSObjectProtocol] = []
    
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
                
                // Tip
                tipSection
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Apply Button
                applyButton
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.15, green: 0.18, blue: 0.22))
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
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
            sectionHeader("Cursor Settings")
            
            VStack(spacing: 16) {
                SettingRow(label: "Cursor Color:") {
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
                
                SettingRow(label: "Click Color:") {
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
                
                SettingRow(label: "Cursor Size:") {
                    SizePickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.size },
                            set: { CursorSettings.shared.size = $0 }
                        )
                    )
                }
                
                SettingRow(label: "Cursor Shape:") {
                    ShapePickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.shape },
                            set: { CursorSettings.shared.shape = $0 }
                        )
                    )
                }
                
                SettingRow(label: "Inner Glow Style:") {
                    InnerGlowStylePickerView(
                        selection: Binding(
                            get: { CursorSettings.shared.innerGlowStyle },
                            set: { CursorSettings.shared.innerGlowStyle = $0 }
                        )
                    )
                }
                
                SettingRow(label: "Outer Line Width:") {
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
                
                SettingRow(label: "Transparency:") {
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
                
                SettingRow(label: "Shadow Brightness:") {
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
                
                SettingRow(label: "Hide When Inactive:") {
                    Toggle("", isOn: Binding(
                        get: { CursorSettings.shared.hideWhenInactive },
                        set: { CursorSettings.shared.hideWhenInactive = $0 }
                    ))
                    .toggleStyle(.switch)
                }
                
                SettingRow(label: "Glow Effect:") {
                    Toggle("", isOn: Binding(
                        get: { CursorSettings.shared.cursorGlowEnabled },
                        set: { CursorSettings.shared.cursorGlowEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                }
                
                SettingRow(label: "Gradient Color:") {
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
    
    // MARK: - Tip Section
    private var tipSection: some View {
        Text("💡 Tip: ⌘ + Click opens menu and closes pencil mode")
            .font(.system(size: 11))
            .foregroundColor(settings.textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Apply Button
    private var applyButton: some View {
        Button("Apply") {
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
        
        notificationObservers = [observer1, observer2, observer3, observer4, observer5, observer6, observer7, observer8, observer9, observer10, observer11, observer12]
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
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(label)
                .frame(width: 180, alignment: .leading)
                .foregroundColor(settings.textColor)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 35)
    }
}

// MARK: - Color Picker View
struct ColorPickerView: View {
    @Binding var selection: CursorColor
    let onSelectionChange: ((CursorColor) -> Void)?
    
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
        .onChange(of: selection) { newValue in
            onSelectionChange?(newValue)
        }
    }
}

// MARK: - Size Picker View
struct SizePickerView: View {
    @Binding var selection: CursorSize
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CursorSize.allCases, id: \.self) { size in
                Text(size.displayName).tag(size)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .onChange(of: selection) { _ in
            CursorSettings.shared.size = selection
        }
    }
}

// MARK: - Shape Picker View
struct ShapePickerView: View {
    @Binding var selection: CursorShape
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CursorShape.allCases, id: \.self) { shape in
                Text(shape.displayName).tag(shape)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .onChange(of: selection) { _ in
            CursorSettings.shared.shape = selection
        }
    }
}

// MARK: - Inner Glow Style Picker View
struct InnerGlowStylePickerView: View {
    @Binding var selection: InnerGlowStyle
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(InnerGlowStyle.allCases, id: \.self) { style in
                Text(style.displayName).tag(style)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 320)
        .onChange(of: selection) { _ in
            CursorSettings.shared.innerGlowStyle = selection
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

