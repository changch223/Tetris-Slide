import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("KEY_ABOUT_TITLE")
                    .font(.title2.weight(.bold))
                Text("KEY_ABOUT_BODY_1")
                Text("KEY_ABOUT_BODY_2")
                Text("KEY_ABOUT_CREDITS")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
        }
        .navigationTitle(Text("KEY_ABOUT"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { AboutView() }
}
