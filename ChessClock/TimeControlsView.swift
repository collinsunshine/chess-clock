import SwiftUI

struct TimeControlsView: View {
    let presets: [TimeControlPreset]
    let selectedIndex: Int
    let isGameInProgress: Bool
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<presets.count, id: \.self) { index in
                    Button(action: {
                        onSelect(index)
                    }) {
                        HStack {
                            Text(presets[index].name)
                                .font(.headline)
                            
                            Spacer()
                            
                            if index == selectedIndex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Time Controls")
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