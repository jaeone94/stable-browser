import SwiftUI
struct MaskInvertPicker: View {
    @Binding var maskInvert: Int
    
    var body: some View {
        Picker(selection: $maskInvert, label: Text("Mask mode")) {
            Text("Inpaint Masked").tag(0)
            Text("Inpaint Not Masked").tag(1)
        }
    }
}
