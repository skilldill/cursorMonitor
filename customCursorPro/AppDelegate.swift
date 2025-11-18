//
//  AppDelegate.swift
//  customCursorPro
//
//  Created by Alexander on 18.11.2025.
//


import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let highlighter = CursorHighlighter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        highlighter.start() // включаем подсветку сразу (можно убрать, если хочешь вручную)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "◉" // Можно заменить на свою иконку
        }

        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "Toggle Highlight",
            action: #selector(toggleHighlight),
            keyEquivalent: "t"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleHighlight() {
        if highlighter.isRunning {
            highlighter.stop()
        } else {
            highlighter.start()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
