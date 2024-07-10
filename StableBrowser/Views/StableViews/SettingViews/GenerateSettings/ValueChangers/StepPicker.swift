import SwiftUI
struct StepsPicker: View {
    @Binding var steps: Int
    
    var body: some View {
        Picker(selection: $steps, label: Text("Sampling steps")) {
            ForEach(0..<151) { index in
                Text("\(index)")
            }
        }
    }
}
