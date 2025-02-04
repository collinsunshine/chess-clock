import SwiftUI

struct SettingsView: View {
    @Binding var isSoundEnabled: Bool
    @Binding var showMoveCounter: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Toggle("Sound Effects", isOn: $isSoundEnabled)
                Toggle("Show Move Counter", isOn: $showMoveCounter)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color(.quaternarySystemFill))
                    .cornerRadius(14)
            })
        }
    }
} 