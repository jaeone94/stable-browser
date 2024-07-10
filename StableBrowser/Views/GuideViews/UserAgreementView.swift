import Foundation
import SwiftUI

struct UserAgreementView: View {
    @AppStorage("userAgreedToTerms") private var userAgreedToTerms = false
    @State private var agreementChecked = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("User Agreement")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 30)
                
                ScrollView {
                    VStack {
                        Text(agreementText)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .padding()
                            .multilineTextAlignment(.leading)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .frame(height: UIScreen.main.bounds.height * 0.5)
                
                Toggle(isOn: $agreementChecked) {
                    Text("I agree to the terms and conditions")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding(.horizontal)
                
                Button(action: {
                    if agreementChecked {
                        userAgreedToTerms = true
                    }
                }) {
                    Text("Confirm")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(agreementChecked ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!agreementChecked)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding()
        }
    }
    
    private var agreementText: String {
        """
        By using this application, I hereby agree to the following terms and conditions:

        1. I will not use this app to create, distribute, or promote any content that is offensive, pornographic, explicit, or violates any applicable laws or regulations.

        2. I understand that all images generated using this app are for personal use only and should not be used for commercial purposes without proper licensing and permissions.

        3. I acknowledge that I am solely responsible for any content I create or actions I take while using this app, and I will not hold the developers or distributors of this app liable for any consequences resulting from my use of the app.

        4. I will respect intellectual property rights and will not use this app to infringe upon copyrights, trademarks, or other protected materials.

        5. I understand that the app developers reserve the right to terminate my access to the app if I violate these terms or engage in any abusive or harmful behavior.

        6. I am aware that the images generated by this app are artificial and do not represent real individuals or events.

        7. I will use this app responsibly and ethically, considering the potential impact of the content I create on others and society.

        By checking the box below, I confirm that I have read, understood, and agree to abide by these terms and conditions. I also confirm that I am of legal age to enter into this agreement in my jurisdiction.
        """
    }
}
