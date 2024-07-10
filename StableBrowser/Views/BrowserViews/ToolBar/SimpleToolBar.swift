import SwiftUI

struct SimpleToolBar: View {
    // MARK: - Properties
    var parent: BrowserView
    var isKeyboardOpen: Bool
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            parent.materializeToolbar()
        }) {
            GeometryReader { geometry in
                Text(parent.browserViewModel.currentTitle)
                    .font(.system(size: 14))
                    .frame(width: geometry.size.width - 20)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
            }
            .frame(height: isKeyboardOpen ? 35 : 45)
        }
    }
}
