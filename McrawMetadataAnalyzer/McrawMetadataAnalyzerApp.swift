//
//  McrawMetadataAnalyzerApp.swift
//  McrawMetadataAnalyzer
//
//  Created by Sebastijan on 17.12.2025..
//

import SwiftUI
internal import UniformTypeIdentifiers

@main
struct McrawMetadataAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open MCRAW File...") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let openFile = Notification.Name("openFile")
}
