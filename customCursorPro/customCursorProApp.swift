//
//  customCursorProApp.swift
//  customCursorPro
//
//  Created by Alexander on 18.11.2025.
//

import SwiftUI

@main
struct customCursorProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Убираем главное окно — приложение живёт только в меню-баре
        Settings {
            EmptyView()
        }
    }
}
