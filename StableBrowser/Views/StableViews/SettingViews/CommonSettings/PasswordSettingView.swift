import SwiftUI

struct PasswordSettingView: View {
    var parent: StableSettingsView
    @Environment(\.presentationMode) var presentationMode
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var useBiometricAuthentication: Bool = false
    @State private var isConfirmingPassword: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var isBiometricAuthenticationAvailable: Bool = false

    @State private var alertType: AlertType = .passwordMismatch

    private enum AlertType {
        case passwordMismatch
        case biometricAuthenticationError
    }
    
    var isPortraitMode: Bool {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return false
            } else {
                return verticalSizeClass == .regular
            }
        }
    }
    
    // MARK: - Environment
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        VStack {
            Text(isConfirmingPassword ? "Confirm Password" : "Set Password")
                .font(.title)
                .padding()
            
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "circle.fill")
                        .foregroundColor((isConfirmingPassword ? confirmPassword : password).count > index ? Color(UIColor.label) : Color(UIColor.systemGray4))
                }
            }
            .padding()
            
            NumberPad(password: isConfirmingPassword ? $confirmPassword : $password, isLandscape: !isPortraitMode)
                .padding()
                .onChange(of: password) {
                    oldValue, newValue in
                    if newValue.count == 6 {
                        isConfirmingPassword = true
                        confirmPassword = ""
                    }
                }
                .onChange(of: confirmPassword) {
                    oldValue, newValue in
                    if newValue.count == 6 {
                        setPassword()
                    }
                }
            
            // Round CheckBox 
            HStack {
                if isBiometricAuthenticationAvailable {
                    Image(systemName: useBiometricAuthentication ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            useBiometricAuthentication.toggle()
                        }
                    
                    Text("Use Biometric Authentication")
                        .font(.headline)
                        .padding()
                }
            }.frame(height: 100)
        }
        .alert(isPresented: $showErrorAlert) {
            switch alertType {
            case .passwordMismatch:
                return Alert(title: Text("Password Mismatch"),
                  message: Text("The entered passwords do not match. Please try again."),
                  dismissButton: .default(Text("OK")))
            case .biometricAuthenticationError:
                return Alert(title: Text("Biometric Authentication Error"),
                  message: Text("Biometric authentication failed. Would you like to set a password without biometric authentication?"),
                    primaryButton: .default(Text("Yes")) {
                        useBiometricAuthentication = false
                        setPassword()
                    },
                    secondaryButton: .cancel(Text("No")) {
                        password = ""
                        confirmPassword = ""
                        isConfirmingPassword = false
                    })
            }            
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            isBiometricAuthenticationAvailable = AuthenticationService.shared.isBiometricAuthenticationAvailable()
        }
    }
    
    private func setPassword() {
        if password == confirmPassword {
            // Password setting logic
            if useBiometricAuthentication {
                AuthenticationService.shared.authenticateUserWithBiometrics { success, error in
                    if success {
                        AuthenticationService.shared.setPassword(password, usedBiometrics: true)
                        presentationMode.wrappedValue.dismiss()
                        parent.triggerRedraw.toggle()
                    } else {
                        alertType = .biometricAuthenticationError
                        showErrorAlert = true
                    }
                }
            } else {
                AuthenticationService.shared.setPassword(password, usedBiometrics: false)
                presentationMode.wrappedValue.dismiss()
                parent.triggerRedraw.toggle()
            }
        } else {
            // Password mismatch error handling
            alertType = .passwordMismatch
            showErrorAlert = true
            password = ""
            confirmPassword = ""
            isConfirmingPassword = false
        }
    }
}

struct NumberPad: View {
    @Binding var password: String
    var isLandscape: Bool

    var isEditable: Bool {
        // Password is not editable if it has more than 6 characters
        return password.count < 6
    }
    
    var body: some View {
        VStack {
            if isLandscape {
                VStack {
                    ForEach(0..<2) { row in
                        HStack {
                            ForEach(0..<5) { column in
                                let number = row * 5 + column
                                if number < 10 {
                                    Button(action: {
                                        if isEditable {
                                            password += "\(number)"
                                        }
                                    }) {
                                        Text("\(number)")
                                            .font(.title)
                                            .frame(width: 80, height: 80)
                                            .background(Color(UIColor.secondarySystemBackground))
                                            .cornerRadius(40)
                                            .foregroundColor(isEditable ? .primary : .secondary)
                                    }
                                    .disabled(!isEditable)
                                } else {
                                    Button(action: {
                                        password = String(password.dropLast())
                                    }) {
                                        Image(systemName: "delete.left")
                                            .font(.title)
                                            .frame(width: 80, height: 80)
                                            .background(Color(UIColor.secondarySystemBackground))
                                            .cornerRadius(40)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                VStack {
                    ForEach(0..<3) { row in
                        HStack {
                            ForEach(1..<4) { column in
                                let number = row * 3 + column
                                Button(action: {
                                    if isEditable {
                                        password += "\(number)"
                                    }
                                }) {
                                    Text("\(number)")
                                        .font(.title)
                                        .frame(width: 80, height: 80)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(40)
                                        .foregroundColor(isEditable ? .primary : .secondary)
                                }
                                .disabled(!isEditable)
                            }
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            password = String(password.dropLast())
                        }) {
                            Image(systemName: "delete.left")
                                .font(.title)
                                .frame(width: 80, height: 80)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(40)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            if isEditable {
                                password += "0"
                            }
                        }) {
                            Text("0")
                                .font(.title)
                                .frame(width: 80, height: 80)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(40)
                                .foregroundColor(isEditable ? .primary : .secondary)
                        }.disabled(!isEditable)
                        
                        Spacer()
                            .frame(width: 80)
                    }
                }
            }
        }
    }
}
