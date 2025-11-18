//
//  CursorHighlighter.swift
//  customCursorPro
//
//  Created by Alexander on 18.11.2025.
//


import Cocoa

final class CursorHighlighter {

    private var window: NSWindow?
    private var highlightView: HighlightView?
    private var mouseMoveMonitor: Any?
    private var clickMonitor: Any?
    private var releaseMonitor: Any?

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
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        mouseMoveMonitor = nil
        clickMonitor = nil
        releaseMonitor = nil
        window?.orderOut(nil)
    }

    private func createWindowIfNeeded() {
        guard window == nil else { return }

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let initialRect = NSRect(
            x: screenFrame.midX - diameter / 2,
            y: screenFrame.midY - diameter / 2,
            width: diameter,
            height: diameter
        )

        let win = NSWindow(
            contentRect: initialRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.ignoresMouseEvents = true
        win.level = .screenSaver  // поверх всего
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = HighlightView(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter))
        view.wantsLayer = true

        win.contentView = view
        win.orderFrontRegardless()

        self.window = win
        self.highlightView = view
    }

    private func startMonitoring() {
        // Глобальный монитор движения мыши
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updatePosition(with: event)
        }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [weak self] event in
            self?.handleMouseDown()
        }

        releaseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseUp]
        ) { [weak self] event in
            self?.handleMouseUp()
        }
    }

    private func updatePosition(with event: NSEvent) {
        guard let window = window else { return }

        // Координаты в системе окон AppKit — уже глобальные для главного экрана
        let location = event.locationInWindow

        let newOrigin = NSPoint(
            x: location.x - diameter / 2,
            y: location.y - diameter / 2
        )

        window.setFrameOrigin(newOrigin)
        window.orderFrontRegardless()
    }

    private func handleClick(event: NSEvent) {
        guard let view = highlightView else { return }
        view.pulse()
    }
    
    func handleMouseDown() {
        highlightView?.beginClick()
    }

    func handleMouseUp() {
        highlightView?.endClick()
    }
}
