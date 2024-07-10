import SwiftUI

struct MaskBlurPicker: View {
    @Binding var maskBlur: Int
    
    var body: some View {
        Picker(selection: $maskBlur, label: Text("Mask Blur")) {
            ForEach(0..<65) { index in
                Text("\(index)")
            }
        }
    }
}
