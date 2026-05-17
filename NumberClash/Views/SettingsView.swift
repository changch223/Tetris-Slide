import SwiftUI

struct SettingsView: View {
    @State private var settings: Settings

    private let store: SettingsStore

    init(store: SettingsStore = UserDefaultsSettingsStore()) {
        self.store = store
        _settings = State(initialValue: store.load())
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.soundEnabled) {
                    Label("KEY_SETTINGS_SOUND", systemImage: "speaker.wave.2")
                }
                Toggle(isOn: $settings.hapticsEnabled) {
                    Label("KEY_SETTINGS_HAPTICS", systemImage: "iphone.radiowaves.left.and.right")
                }
            } header: {
                Text("KEY_SETTINGS_FEEDBACK_HEADER")
            }
        }
        .navigationTitle(Text("KEY_SETTINGS"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings) { _, newValue in
            store.save(newValue)
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
