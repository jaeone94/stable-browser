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
            if let savedAddress = stableSettingViewModel.ip {
                if savedAddress.contains("://") {
                    self.url = savedAddress
                    self.connectionType = 1
                } else {
                    let components = savedAddress.split(separator: ":")
                    if components.count > 1 {
                        self.ipAddress = String(components[0])
                        self.port = String(components[1])
                    } else {
                        self.ipAddress = savedAddress
                    }
                    self.connectionType = 0
                }
            }
            if let savedPort = stableSettingViewModel.port, self.connectionType == 0 {
                self.port = savedPort
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
        let address = connectionType == 0 ? ipAddress : url
        let (cleanAddress, useHttps, cleanPort) = StringUtils.processAddress(address, port: port)
        let api = WebUIApi(host: cleanAddress, port: cleanPort, useHttps: useHttps)
        
        Task {
            if let options = await api.getOptions() {
                stableSettingViewModel.webUIApi = api
                stableSettingViewModel.ip = address
                stableSettingViewModel.port = String(cleanPort)
                isConnected = true
                
                DispatchQueue.main.async {
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
                
                OverlayService.shared.hideOverlaySpinner()
                Toast.shared.present(
                    title: "Server connected",
                    symbol: "checkmark.circle.fill",
                    isUserInteractionEnabled: true,
                    timing: .medium
                )
            } else {
                DispatchQueue.main.async {
                    stableSettingViewModel.isConnected = false
                    isConnected = false
                    OverlayService.shared.hideOverlaySpinner()
                    showAlert = true
                }
            }
        }
    }
}
