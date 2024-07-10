import Foundation
import SwiftUI

struct UserAgreementView: View {
    @AppStorage("userAgreedToTerms") private var userAgreedToTerms = false
    @State private var agreementChecked = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("End-User License Agreement (EULA)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, 30)
                    
                    Text(eulaText)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .padding()
                        .multilineTextAlignment(.leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    Toggle(isOn: $agreementChecked) {
                        Text("I have read and agree to the terms of this EULA")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal)
                    
                    Button(action: {
                        if agreementChecked {
                            userAgreedToTerms = true
                        }
                    }) {
                        Text("Accept")
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
            }
        }
    }
    
    private var eulaText: String {
        """
        END-USER LICENSE AGREEMENT

        IMPORTANT: PLEASE READ THIS END-USER LICENSE AGREEMENT CAREFULLY BEFORE USING STABLEBROWSER.

        1. ACCEPTANCE OF TERMS

        By using StableBrowser ("the App"), you agree to be bound by the terms of this End-User License Agreement ("EULA"). If you do not agree to these terms, do not use the App.

        2. LICENSE GRANT

        Subject to your compliance with this EULA, we grant you a limited, non-exclusive, non-transferable, revocable license to use the App for your personal, non-commercial use.

        3. RESTRICTIONS ON USE

        You agree not to:
        a) Use the App to create, distribute, or promote offensive, pornographic, or explicit content.
        b) Violate any applicable laws or regulations while using the App.
        c) Infringe upon intellectual property rights of others.
        d) Use the App for any commercial purposes without proper licensing.
        e) Attempt to reverse engineer, modify, or create derivative works of the App.

        4. USER-GENERATED CONTENT

        You are solely responsible for any content you create using the App. You agree not to create content that is illegal, harmful, or infringes on others' rights.

        5. INTELLECTUAL PROPERTY

        The App and its original content are and will remain the exclusive property of the App developers. The App is protected by copyright, trademark, and other laws.

        6. DISCLAIMER OF WARRANTY

        The App is provided "AS IS" without warranty of any kind. We disclaim all warranties, express or implied, including but not limited to merchantability and fitness for a particular purpose.

        7. LIMITATION OF LIABILITY

        To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the App.

        8. TERMINATION

        We reserve the right to terminate your access to the App if you violate this EULA or engage in any abusive or harmful behavior.

        9. CHANGES TO THIS AGREEMENT

        We reserve the right to modify this EULA at any time. Your continued use of the App after such modifications constitutes your acceptance of the new terms.

        10. GOVERNING LAW

        This EULA shall be governed by the laws of the jurisdiction in which the App developers are based, without regard to its conflict of law provisions.

        By using StableBrowser, you acknowledge that you have read this EULA, understand it, and agree to be bound by its terms and conditions.
        """
    }
}
