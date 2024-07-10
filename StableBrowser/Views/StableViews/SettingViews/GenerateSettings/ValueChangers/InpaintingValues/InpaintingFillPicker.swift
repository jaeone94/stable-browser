import SwiftUI
struct InpaintingFillPicker: View {
    @Binding var inpaintingFill: Int
    
    var body: some View {
        Picker(selection: $inpaintingFill, label: Text("Masked content")) {
            Text("Original").tag(0)
            Text("Fill").tag(1)
        }
    }
}
