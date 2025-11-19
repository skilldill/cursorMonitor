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
    private var settingsWindow: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        highlighter.start() // включаем подсветку сразу (можно убрать, если хочешь вручную)
        
        // Подписываемся на уведомления об открытии/закрытии окна настроек
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsWindowWillOpen),
            name: .settingsWindowWillOpen,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsWindowWillClose),
            name: .settingsWindowWillClose,
            object: nil
        )
    }
    
    @objc private func settingsWindowWillOpen() {
        // Останавливаем курсор при открытии настроек
        if highlighter.isRunning {
            highlighter.stop()
        }
    }
    
    @objc private func settingsWindowWillClose() {
        // Возобновляем курсор при закрытии настроек
        if !highlighter.isRunning {
            highlighter.start()
        }
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
        
        let settingsItem = NSMenuItem(
            title: "Настройки...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

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
    
    @objc private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow()
        }
        settingsWindow?.showWindow()
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
