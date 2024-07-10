import SwiftUI

struct ChangePasswordView: View {
    var parent: StableSettingsView
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var useBiometricAuthentication: Bool = false
    @State private var stage: PasswordStage = .current
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var isBiometricAuthenticationAvailable: Bool = false
    
    @State private var alertType: AlertType = .currentPasswordMismatch

    private enum AlertType {
        case currentPasswordMismatch
        case newPasswordMismatch
        case biometricAuthenticationError
    }
    
    enum PasswordStage {
        case current
        case new
        case confirm
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
            Text(stageTitle)
                .font(.title)
                .padding()
            
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "circle.fill")
                        .foregroundColor(currentPasswordInput.count > index ? Color(UIColor.label) : Color(UIColor.systemGray4))
                }
            }
            .padding()
            
            NumberPad(password: currentPasswordBinding, isLandscape: !isPortraitMode)
                .padding()
                .onChange(of: currentPasswordInput) { oldValue, newValue in
                    if newValue.count == 6 {
                        switch stage {
                        case .current:
                            if AuthenticationService.shared.validatePassword(currentPassword) {
                                stage = .new
                                newPassword = ""
                            } else {
                                alertType = .currentPasswordMismatch
                                showErrorAlert = true                                
                                currentPassword = ""
                            }
                        case .new:
                            stage = .confirm
                            confirmPassword = ""
                        case .confirm:
                            setPassword()
                        }
                    }
                }
                        
            HStack {
                if stage != .current && isBiometricAuthenticationAvailable {
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
            }
            .frame(height: 100)
        }
        .alert(isPresented: $showErrorAlert) {
            switch alertType {
            case .currentPasswordMismatch:
                return Alert(title: Text("Password Mismatch"), message: Text("Please try again."), dismissButton: .default(Text("OK")))
            case .newPasswordMismatch:
                return Alert(title: Text("Password Mismatch"), message: Text("The entered passwords do not match. Please try again."), dismissButton: .default(Text("OK")))
            case .biometricAuthenticationError:
                return Alert(title: Text("Biometric Authentication Error"),
                  message: Text("Biometric authentication failed. Do you want to set the password without biometric authentication?"),
                    primaryButton: .default(Text("Yes")) {
                        useBiometricAuthentication = false
                        setPassword()
                    },
                    secondaryButton: .cancel(Text("No")) {
                        newPassword = ""
                        confirmPassword = ""
                        stage = .new
                    })
            }
            
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            isBiometricAuthenticationAvailable = AuthenticationService.shared.isBiometricAuthenticationAvailable()
        }
    }
    
    private var stageTitle: String {
        switch stage {
        case .current:
            return "Enter Current Password"
        case .new:
            return "Enter New Password"
        case .confirm:
            return "Confirm New Password"
        }
    }
    
    private var currentPasswordInput: String {
        switch stage {
        case .current:
            return currentPassword
        case .new:
            return newPassword
        case .confirm:
            return confirmPassword
        }
    }
    
    private var currentPasswordBinding: Binding<String> {
        switch stage {
        case .current:
            return $currentPassword
        case .new:
            return $newPassword
        case .confirm:
            return $confirmPassword
        }
    }
    
    private func setPassword() {
        if newPassword == confirmPassword {
            // Set password logic
            if useBiometricAuthentication {
                AuthenticationService.shared.authenticateUserWithBiometrics { success, error in
                    if success {
                        AuthenticationService.shared.setPassword(newPassword, usedBiometrics: true)
                        presentationMode.wrappedValue.dismiss()
                        parent.triggerRedraw.toggle()
                    } else {
                        alertType = .biometricAuthenticationError
                        showErrorAlert = true
                    }
                }
            } else {
                AuthenticationService.shared.setPassword(newPassword, usedBiometrics: false)
                presentationMode.wrappedValue.dismiss()
                parent.triggerRedraw.toggle()
            }
        } else {
            // Handle password mismatch error
            alertType = .newPasswordMismatch
            showErrorAlert = true            
            newPassword = ""
            confirmPassword = ""
            stage = .new
        }
    }
}
