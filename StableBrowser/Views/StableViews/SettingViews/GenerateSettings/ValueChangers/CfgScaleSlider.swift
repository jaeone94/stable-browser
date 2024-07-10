import SwiftUI
struct CfgScaleSlider: View {
    @Binding var cfgScale: Double
    
    var body: some View {
        VStack {
            HStack {
                Text("Cfg Scale")
                Spacer()
                Text("\(cfgScale, specifier: "%.2f")")
            }
            Slider(value: $cfgScale, in: 0...35, step: 0.5)
        }
    }
}
