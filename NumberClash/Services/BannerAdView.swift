// Banner ads disabled. Entire implementation commented out per request;
// all call sites (GameView / MainMenuView) had their references removed.
/*
import SwiftUI
import GoogleMobileAds

enum AdUnitIDs {
    /// Google's well-known banner test ID. Swap to the real production unit ID
    /// before App Store submission (see quickstart.md §7).
    static let banner = "ca-app-pub-3940256099942544/2934735716"
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdUnitIDs.banner) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
*/
