import SwiftUI
struct SeedTextField: View {
    @Binding var seed: Int
    
    var body: some View {
        HStack {
            Text("Seed")
            Spacer()
            TextField("Seed", value: $seed, formatter: NumberFormatter())
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .padding(.leading, 20)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1)
        }
    }
}
