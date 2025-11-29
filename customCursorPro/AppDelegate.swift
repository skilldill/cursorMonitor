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
    private var shortcutsWindow: ShortcutsWindow?

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
        
        // Подписываемся на изменения языка
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc private func languageChanged() {
        // Обновляем меню при изменении языка
        setupStatusItem()
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
            // Загружаем иконку из Assets (теперь она в основном Assets.xcassets, а не в Preview)
            if let iconImage = NSImage(named: "MenuBarIcon") {
                // Устанавливаем размер для меню-бара (22x22 для Retina = 44x44)
                iconImage.size = NSSize(width: 22, height: 22)
                // Делаем изображение шаблоном для правильного отображения в светлой/темной теме
                iconImage.isTemplate = true
                button.image = iconImage
                button.imagePosition = .imageOnly
            } else {
                // Fallback на текст, если изображение не найдено
                button.title = "◉"
            }
        }

        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: L("menu.toggleHighlight"),
            action: #selector(toggleHighlight),
            keyEquivalent: "t"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())
        
        let shortcutsItem = NSMenuItem(
            title: L("menu.keyboardShortcuts"),
            action: #selector(showShortcuts),
            keyEquivalent: ""
        )
        shortcutsItem.target = self
        menu.addItem(shortcutsItem)
        
        let settingsItem = NSMenuItem(
            title: L("menu.settings"),
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: L("menu.quit"),
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
    
    @objc private func showShortcuts() {
        if shortcutsWindow == nil {
            shortcutsWindow = ShortcutsWindow()
        }
        shortcutsWindow?.showWindow()
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
