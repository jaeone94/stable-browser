import SwiftUI

struct SpinnerView: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding(20)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
            .transition(.opacity)
            .zIndex(1)
        }
    }
}
