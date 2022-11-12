//
//  APOD_SwiftUIApp.swift
//

import Combine
import SwiftUI

@main
struct APOD_SwiftUIApp: App {
    let pictureOfTheDay = PictureOfTheDay()

    init() {
        guard !CommandLine.arguments.contains("TESTING") else { return }
        self.pictureOfTheDay.load()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .padding()
                .environmentObject(pictureOfTheDay)
        }
        .commands {
            CommandMenu("Date") {
                Button(action: { self.pictureOfTheDay.incrementDate(by: -1) }) { Text("Previous") }
                    .keyboardShortcut("[")
                Button(action: { self.pictureOfTheDay.incrementDate(by: 1) }) { Text("Next") }
                    .keyboardShortcut("]")
            }
        }
    }
}
