import Foundation
import UIKit
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

/// Drives the start-of-app consent + ads-init flow.
///
/// Sequence (research R-4):
///   1. Refresh UMP consent info (GDPR-relevant regions only show a form)
///   2. Present UMP consent form if required
///   3. Request ATT authorization (iOS-wide, only if not already prompted)
///   4. `MobileAds.shared.start(...)`
///
/// Persists `tetris2048.consent.attHasPrompted` and `tetris2048.consent.umpDecisionAt`
/// (persistence-contract.md). Safe to call repeatedly: short-circuits on the
/// 2nd+ launch.
final class AdConsentCoordinator {
    static let shared = AdConsentCoordinator()

    private let defaults: UserDefaults
    private var hasStarted = false

    static let attPromptedKey  = "tetris2048.consent.attHasPrompted"
    static let umpDecisionKey  = "tetris2048.consent.umpDecisionAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    @MainActor
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        await runUMPFlow()
        await runATTPromptIfNeeded()
        MobileAds.shared.start(completionHandler: nil)
    }

    // MARK: - UMP

    @MainActor
    private func runUMPFlow() async {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] (_: Error?) in
                guard let self else { continuation.resume(); return }
                Task { @MainActor in
                    await self.presentUMPFormIfNeeded()
                    self.defaults.set(Date(), forKey: Self.umpDecisionKey)
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func presentUMPFormIfNeeded() async {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UMPConsentForm.loadAndPresentIfRequired(from: rootVC) { (_: Error?) in
                continuation.resume()
            }
        }
    }

    // MARK: - ATT

    @MainActor
    private func runATTPromptIfNeeded() async {
        guard !defaults.bool(forKey: Self.attPromptedKey) else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
        defaults.set(true, forKey: Self.attPromptedKey)
    }
}
