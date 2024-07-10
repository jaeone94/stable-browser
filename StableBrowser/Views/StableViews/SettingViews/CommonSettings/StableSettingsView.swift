import SwiftUI


struct StableSettingsView: View {
    @StateObject var stableSettingViewModel = StableSettingViewModel.shared
    @State private var showAlert = false
    @State private var alertType: AlertType = .askClearCache
    @State internal var triggerRedraw: Bool = false
    @State var clipSkip : Int = 0
    
    @State var isConnectedServer: Bool = false
    
    enum AlertType {
        case cacheClearSuccess
        case askClearCache
    }
    
    @StateObject var browserViewModel = BrowserViewModel.shared
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Server connection")) {
                    NavigationLink(destination: ServerConnectionView()) {
                        HStack {
                            Text("CONNECTION STATUS")
                            Spacer()
                            Circle()
                                .fill(isConnectedServer ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                
                if isConnectedServer {
                    Section(header: Text("General settings")) {
                        if let options = stableSettingViewModel.options {
                            // SD Models
                            NavigationLink(destination: SDModelSettingView(parent: self, title: "SD Models", modelName: options.sd_model_checkpoint, key: "sd-models")) {
                                HStack {
                                    Text("Check point")
                                    Spacer()
                                    Text(stableSettingViewModel.selectedSDModel)
                                        .lineLimit(1)
                                        .padding(.leading, 20)
                                }
                            }
                            .onChange(of: stableSettingViewModel.selectedSDModel) { oldValue, newValue in
                                OverlayService.shared.hideOverlaySpinner()
                            }
                        }
                        
                        let sdVaes = stableSettingViewModel.sdVAEs
                        if !sdVaes.isEmpty {
                            // SD VAE
                            NavigationLink(destination: SDVAESettingView(parent: self, title: "SD VAE", modelName: stableSettingViewModel.selectedSdVae)) {
                                HStack {
                                    Text("SD VAE")
                                    Spacer()
                                    Text(stableSettingViewModel.selectedSdVae)
                                        .lineLimit(1)
                                        .padding(.leading, 20)
                                }
                            }
                        }
                        
                        
                        // Clip Skip (0 ~ 10)
                        HStack {
                            Text("Clip Skip")
                            Spacer()
                            Stepper(value: $clipSkip, in: 1...10) {
                                Text("\(clipSkip)")
                            }
                            .onChange(of: clipSkip) { oldValue, newValue in
                                stableSettingViewModel.clipSkip = newValue
                            }
                        }
                    }
                }
                
                Section(header: Text("Application settings")) {
                    let isPasswordSet = AuthenticationService.shared.isPasswordSet()
                    // If isDefaultPassword is false, go to the password change view (enter the current password and if successful, change to a new password)
                    if !isPasswordSet {
                        NavigationLink(destination: PasswordSettingView(parent: self)) {
                            HStack {
                                Text("Set Password")
                                Spacer()
                                Image(systemName: "lock")
                            }
                        }
                    }
                    // If isDefaultPassword is false, go to the password change view (enter the current password and if successful, change to a new password)
                    else {
                        NavigationLink(destination: ChangePasswordView(parent: self)) {
                            HStack {
                                Text("Change password")
                                Spacer()
                                Image(systemName: "lock")
                            }
                        }
                    }
                }.id(triggerRedraw)
                
                Section(header: Text("Browser settings")) {
                    // Clear cache and cookies button
                    Button(action: {
                        alertType = .askClearCache
                        showAlert = true
                    }) {
                        HStack {
                            Text("Clear cache and cookies")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                }
            }.onAppear {
                clipSkip = stableSettingViewModel.clipSkip
                isConnectedServer = stableSettingViewModel.isConnected ?? false
            }.alert(isPresented: $showAlert) {
                switch alertType {
                case .cacheClearSuccess:
                    return Alert(title: Text("Cache and cookies cleared"), message: Text("Cache and cookies have been cleared successfully."), dismissButton: .default(Text("OK")))
                case .askClearCache:
                    return Alert(title: Text("Clear cache and cookies"), message: Text("Are you sure you want to clear cache and cookies?"), primaryButton: .destructive(Text("Clear")) {
                        browserViewModel.clearCache();
                        browserViewModel.clearCookies();
                        alertType = .cacheClearSuccess
                        showAlert = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showAlert = true
                        }
                    }, secondaryButton: .cancel())
                }
            }
            .navigationBarTitle("SETTINGS", displayMode: .inline)
        }     
        
    }
}
