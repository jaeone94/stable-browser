import SwiftUI
struct InpaintFullResPicker: View {
    @Binding var inpaintFullRes: Int
    
    var body: some View {
        Picker(selection: $inpaintFullRes.animation(), label: Text("Inpaint area")) {
            Text("Whole Picture").tag(0)
            Text("Only Masked").tag(1)
        }
    }
}
