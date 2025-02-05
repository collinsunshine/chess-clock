import SwiftUI

struct SettingsView: View {
    @Binding var isSoundEnabled: Bool
    @Binding var showMoveCounter: Bool
    @Binding var colorScheme: ColorSchemePreference
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Toggle("Sound Effects", isOn: $isSoundEnabled)
                Toggle("Show Move Counter", isOn: $showMoveCounter)
                
                Picker("Appearance", selection: $colorScheme) {
                    ForEach(ColorSchemePreference.allCases) { scheme in
                        Text(scheme.name).tag(scheme)
                    }
                }
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
        .preferredColorScheme(colorScheme.colorScheme)
    }
}

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
} 