import SwiftUI
import AppKit

@main
struct LightweightChatApp: App {
    @StateObject private var chatVM = ChatViewModel()
    @AppStorage("background_theme") private var backgroundThemeRaw = BackgroundTheme.sunshine.rawValue

    private var colorScheme: ColorScheme {
        let theme = BackgroundTheme(rawValue: backgroundThemeRaw) ?? .sunshine
        return theme.usesLightText ? .dark : .light
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatVM)
                .preferredColorScheme(colorScheme)
                .background(WindowAccessor())
        }
        .defaultSize(width: 800, height: 700)
    }
}
