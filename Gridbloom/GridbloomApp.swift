import SwiftUI

@main
struct GridbloomApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var cosmetics = CosmeticsStore()
    @StateObject private var profile = PlayerProfile.shared

    init() {
        MobileAdsBootstrap.startIfNeeded()
        (AdHub.service as? AdMobRewardedAdService)?.preload()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(cosmetics)
                .environmentObject(profile)
                .onAppear {
                    SoundPlayer.shared.prepareSession()
                }
                .task {
                    await cosmetics.load()
                }
        }
    }
}
