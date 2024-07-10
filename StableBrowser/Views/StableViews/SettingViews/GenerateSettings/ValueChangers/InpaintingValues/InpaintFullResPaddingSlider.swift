import SwiftUI
struct InpaintFullResPaddingSlider: View {
    @Binding var inpaintFullResPadding: Int
    @State var inpaintFullResPaddingDouble: Double = 0
    
    var body: some View {
        VStack {
            HStack {
                Text("Inpaint Padding")
                Spacer()
                Text("\(Int(inpaintFullResPaddingDouble))")
            }
            Slider(value: $inpaintFullResPaddingDouble, in: 0...100, step: 1)
                .onChange(of: inpaintFullResPaddingDouble) { oldValue, newValue in
                    inpaintFullResPadding = Int(newValue)
                }
        }
        .onAppear {inpaintFullResPaddingDouble = Double(inpaintFullResPadding)}
    }
}
