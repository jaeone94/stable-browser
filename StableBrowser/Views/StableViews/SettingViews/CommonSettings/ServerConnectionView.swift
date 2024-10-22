import SwiftUI

struct ServerConnectionView: View {
    @StateObject var stableSettingViewModel = StableSettingViewModel.shared
    @State private var connectionType = 0 // 0 for IP, 1 for URL
    @State private var ipAddress = ""
    @State private var url = ""
    @State private var port = "7860"
    @State private var isConnected = false
    @State private var showAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Server connection")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 0)
            
            Picker("Connection Type", selection: $connectionType) {
                Text("IP Address").tag(0)
                Text("URL").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            VStack(alignment: .leading, spacing: 20) {
                if connectionType == 0 {
                    HStack {
                        Text("IP Address")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField("xxx.xxx.xxx.xxx", text: $ipAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text("Port")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField("7860", text: $port)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                } else {
                    HStack {
                        Text("URL")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField("https://example.com", text: $url)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                OverlayService.shared.showOverlaySpinner()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    connectToWebUI()
                }
            }) {
                Text("Connect")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            HStack {
                Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isConnected ? .green : .red)
                    .font(.system(size: 24))
                
                Text(isConnected ? "Connection established" : "Connection not established")
                    .font(.headline)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .onAppear {
            if let savedAddress = stableSettingViewModel.connectedUrl {
                if AddressClassifier.classifyAddress(savedAddress) == .url {
                    self.url = savedAddress
                    self.connectionType = 1
                } else if AddressClassifier.classifyAddress(savedAddress) == .ip {
                    let (_, cleanAddress) = AddressProcessor.extractScheme(from: savedAddress)
                    let components = cleanAddress.split(separator: ":")
                    if components.count > 1 {
                        self.ipAddress = String(components[0])
                        self.port = String(components[1])
                    } else {
                        self.ipAddress = savedAddress
                    }
                    self.connectionType = 0
                }
            }

            if let savedConnectionStatus = stableSettingViewModel.isConnected {
                self.isConnected = savedConnectionStatus
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Server connection failed"), message: Text("Make sure the server is up and running and that the IP/URL and port are correct."), dismissButton: .default(Text("OK")))
        }
    }
    
    private func connectToWebUI() {
        let address = connectionType == 0 ? ("http://" + ipAddress + ":" + (port.isEmpty ? "7860" : port)) : url
        let processedAddress = AddressProcessor.processAddress(address)
        if stableSettingViewModel.webUIApi == nil {
            stableSettingViewModel.webUIApi = WebUIApi.shared
        }
        
        guard let api = stableSettingViewModel.webUIApi else {
            handleConnectionFailure("WebUIApi is not initialized")
            return
        }
        
        do {
            try api.setConnectionProperties(processedAddress)
            
            Task {
                await attemptConnection(api: api, address: address)
            }
        } catch ConnectionError.invalidAddress {
            handleConnectionFailure("Invalid address format")
        } catch ConnectionError.invalidURL {
            handleConnectionFailure("Unable to create URL from address")
        } catch {
            handleConnectionFailure("Unexpected error: \(error.localizedDescription)")
        }
    }

    private func attemptConnection(api: WebUIApi, address: String) async {
        if let options = await api.getOptions() {
            await handleSuccessfulConnection(api: api, address: address, options: options)
        } else {
            handleConnectionFailure("Failed to get options from server")
        }
    }

    private func handleSuccessfulConnection(api: WebUIApi, address: String, options: Options) async {
        stableSettingViewModel.webUIApi = api
        stableSettingViewModel.connectedUrl = address
        isConnected = true
        
        await MainActor.run {
            stableSettingViewModel.isConnected = true
            stableSettingViewModel.options = options
            stableSettingViewModel.selectedSDModel = options.sd_model_checkpoint ?? ""
            self.isConnected = true
        }
        
        stableSettingViewModel.saveLastUrl()
        
        // Call the getSDModels function after successful server connection
        await stableSettingViewModel.getSDModels()
        await stableSettingViewModel.getPromptStyles()
        await stableSettingViewModel.getSamplers()
        await stableSettingViewModel.getSDVAE()
        await stableSettingViewModel.getLoras()
        await stableSettingViewModel.getScheduler()
        
        await MainActor.run {
            OverlayService.shared.hideOverlaySpinner()
            Toast.shared.present(
                title: "Server connected",
                symbol: "checkmark.circle.fill",
                isUserInteractionEnabled: true,
                timing: .medium
            )
        }
    }

    private func handleConnectionFailure(_ message: String) {
        DispatchQueue.main.async {
            stableSettingViewModel.isConnected = false
            isConnected = false
            OverlayService.shared.hideOverlaySpinner()
            showAlert = true
            print("Connection failed: \(message)")
        }
    }
}
