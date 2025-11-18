import Cocoa

final class CursorHighlighter {

    private var window: NSWindow?
    private var highlightView: HighlightView?
    private var mouseMoveMonitor: Any?
    private var clickDownMonitor: Any?
    private var clickUpMonitor: Any?

    private let diameter: CGFloat = 90

    private(set) var isRunning: Bool = false

    func start() {
        guard !isRunning else { return }
        isRunning = true

        createWindowIfNeeded()
        startMonitoring()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        if let monitor = mouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = clickDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = clickUpMonitor {
            NSEvent.removeMonitor(monitor)
        }

        mouseMoveMonitor = nil
        clickDownMonitor = nil
        clickUpMonitor = nil

        window?.orderOut(nil)
    }

    // Создаём прозрачное окно поверх всех экранов/спейсов
    private func createWindowIfNeeded() {
        guard window == nil else { return }

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let initialRect = NSRect(
            x: screenFrame.midX - diameter / 2,
            y: screenFrame.midY - diameter / 2,
            width: diameter,
            height: diameter
        )

        // ВАЖНО: используем NSPanel, а не NSWindow
        let panel = NSPanel(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true

        // Уровень поверх всего
        panel.level = .screenSaver

        // Поведение в Spaces / full screen
        panel.collectionBehavior = [
            .canJoinAllSpaces,    // есть во всех рабочих столах и полноэкранных спейсах
            .fullScreenAuxiliary, // может показываться вместе с fullscreen окнами
            .ignoresCycle         // не мешает cmd+`
        ]

        let view = HighlightView(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter))
        view.wantsLayer = true

        panel.contentView = view
        panel.orderFrontRegardless()

        self.window = panel
        self.highlightView = view
    }


    private func startMonitoring() {
        // Двигаем за мышью по всем экранам
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            self?.updatePositionToMouse()
        }

        // mouseDown → сжимаем фигуру
        clickDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [weak self] _ in
            self?.highlightView?.beginClick()
        }

        // mouseUp → возвращаем в нормальный размер
        clickUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseUp]
        ) { [weak self] _ in
            self?.highlightView?.endClick()
        }
    }

    // Позиционирование окна по глобальным координатам мыши
    private func updatePositionToMouse() {
        guard let window = window else { return }

        // Глобальные координаты курсора (одна система для всех мониторов)
        let location = NSEvent.mouseLocation

        let newOrigin = NSPoint(
            x: location.x - diameter / 2,
            y: location.y - diameter / 2
        )

        window.setFrameOrigin(newOrigin)
        window.orderFrontRegardless()
    }
}
