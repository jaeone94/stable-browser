import SwiftUI
struct DenoisingStrengthSlider: View {
    @Binding var denoisingStrength: Double
    
    var body: some View {
        VStack {
            HStack {
                Text("Denoising Strength")
                Spacer()
                Text("\(denoisingStrength, specifier: "%.2f")")
            }
            Slider(value: $denoisingStrength, in: 0...1, step: 0.01)
        }
    }
}
