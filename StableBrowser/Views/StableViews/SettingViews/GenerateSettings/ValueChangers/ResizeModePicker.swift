import SwiftUI
struct ResizeModePicker: View {
    @Binding var resizeMode: Int
    
    var body: some View {
        Picker(selection: $resizeMode, label: Text("Resize Mode")) {
            Text("Just Resize").tag(0)
            Text("Crop and resize").tag(1)
            Text("Resize and fill").tag(2)
            Text("latent nothing").tag(3)
        }
    }
}
