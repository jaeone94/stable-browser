import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    var retryAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Oops! Something went wrong.")
                .font(.title)
                .padding()
            Text(errorMessage)
                .padding(25)
        }
    }
}
