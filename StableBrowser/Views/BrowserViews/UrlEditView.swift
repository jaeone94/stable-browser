import SwiftUI

struct UrlEditView: View {
    var parent: BrowserView
    @State private var text = "Hello, World!"
    @FocusState internal var isTextFieldFocused
    
    var body: some View {
        VStack {
            if !parent.isPortraitMode {
                UrlTextBox.frame(maxWidth: .infinity, maxHeight: 45)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
            }
            parent.urlEditBookmarkView
            if parent.isPortraitMode {
                UrlTextBox.frame(maxWidth: .infinity, maxHeight: 45)
                    .padding(.horizontal, 20)
                    .padding(.top, 7)
                    .padding(.bottom, 8)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .onAppear {
            self.text = parent.browserViewModel.currentUrl
        }
    }
    
    private var UrlTextBox: some View {
        GeometryReader { geometry in
            ZStack {
                urlBar(geometry: geometry)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                UrlTextField(parent: parent, text: $text, onCommit: commitLoad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 15)
                    .padding(.trailing, 40)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        DispatchQueue.main.async {
                            self.isTextFieldFocused = true
                            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                        }
                    }
                HStack {
                    Spacer()
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                    .padding(.trailing, 13)
                }
            }
        }
    }
    
    private func urlBar(geometry: GeometryProxy) -> some View {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return Rectangle()
                .foregroundColor(Color(UIColor.lightGray).opacity(0.4))
                .frame(width: geometry.size.width, height: geometry.size.height)
            
        } else {
            return Rectangle()
                 .foregroundColor(Color(UIColor.systemBackground).opacity(0.9))
                 .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func commitLoad() {
        parent.webViewModel.load(text)
    }
}
