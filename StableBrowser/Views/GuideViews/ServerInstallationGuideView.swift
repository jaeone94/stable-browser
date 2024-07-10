import SwiftUI
import SafariServices

struct ServerInstallationGuideView: View {
    @State private var selectedEnvironment: Environment = .nvidia
    @State private var showServerConnectionView = false
    @StateObject private var stableSettingViewModel = StableSettingViewModel.shared
    
    enum Environment: String, CaseIterable {
        case nvidia = "NVIDIA GPUs"
        case amd = "AMD GPUs"
        case apple = "Apple Silicon"
        case other = "Other Environments"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A1111/WebUI Server Installation Guide")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select your environment:")
                    .font(.headline)
                
                Picker("Environment", selection: $selectedEnvironment) {
                    ForEach(Environment.allCases, id: \.self) { env in
                        Text(env.rawValue).tag(env)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                installationGuide
                
                detailLink
                
                additionalSetup
                
                serverConnectionStep
            }
            .padding()
        }
        .navigationBarTitle("Server Installation", displayMode: .inline)
        .sheet(isPresented: $showServerConnectionView) {
            ServerConnectionView()
        }
    }
    
    
    @ViewBuilder
    var installationGuide: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Step 1: Installation")
                .font(.title2)
                .fontWeight(.bold)
            
            switch selectedEnvironment {
            case .nvidia:
                nvidiaGuide
            case .amd:
                amdGuide
            case .apple:
                appleGuide
            case .other:
                otherGuide
            }
        }
    }
    
    var detailLink: some View {
        Button(action: {
            if let url = URL(string: guideURL) {
                UIApplication.shared.open(url)
            }
        }) {
            Text("View Detailed Guide")
                .foregroundColor(.blue)
                .underline()
        }
    }
    
    var additionalSetup: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Step 2: Additional Setup for StableBrowser")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("After installing the WebUI server, modify the launch script to enable API access and allow connections from other devices:")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("1. Find 'webui-user.bat' (Windows) or 'webui-user.sh' (macOS/Linux) in your WebUI installation directory.")
                Text("2. Open this file in a text editor.")
                Text("3. Find the line that starts with 'COMMANDLINE_ARGS='")
                Text("4. Add '--api' and '--listen' to the end of this line. Example:")
                Text("COMMANDLINE_ARGS=--xformers --api --listen")
                    .font(.system(size: 14, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                Text("5. Save the file and restart your WebUI server.")
            }
            .textSelection(.enabled)
            
            Text("Now your server should be accessible from StableBrowser.")
                .font(.body)
                .fontWeight(.bold)
        }
    }
    
    var guideURL: String {
        switch selectedEnvironment {
        case .nvidia:
            return "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs"
        case .amd:
            return "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-AMD-GPUs"
        case .apple:
            return "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Installation-on-Apple-Silicon"
        case .other:
            return "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki"
        }
    }
    
    var nvidiaGuide: some View {
        GuideSection(title: "NVIDIA GPUs", content: """
        1. Download the sd.webui.zip from the official repository.
        2. Extract the zip file to your desired location.
        3. Double click the update.bat to update web UI to the latest version.
        4. Double click the run.bat to launch web UI.
        5. Wait for the installation to complete and the server to start.
        """)
    }
    
    var amdGuide: some View {
        GuideSection(title: "AMD GPUs", content: """
        1. Install Python 3.10.6 and git.
        2. Open Command Prompt and run:
           git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
        3. Navigate to the cloned directory and run:
           webui-user.bat
        4. Wait for the installation to complete and the server to start.
        """)
    }
    
    var appleGuide: some View {
        GuideSection(title: "Apple Silicon", content: """
        1. Install Homebrew if not already installed.
        2. Open Terminal and run:
           brew install cmake protobuf rust python@3.10 git wget
        3. Clone the repository:
           git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
        4. Navigate to the cloned directory and run:
           ./webui.sh
        5. Wait for the installation to complete and the server to start.
        """)
    }
    
    var otherGuide: some View {
        GuideSection(title: "Other Environments", content: """
        For other environments or more detailed instructions, please refer to the official wiki.
        Click the 'View Detailed Guide' button below to access the full documentation.
        """)
    }
    
    var serverConnectionStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Step 3: Connect to Your Server")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("1. Find your local IP address:")
                    .fontWeight(.semibold)
                Text("• Windows: Open cmd and type 'ipconfig'")
                Text("• Mac: Open Terminal and type 'ifconfig'")
                
                Text("2. Connect to your server:")
                    .fontWeight(.semibold)
                Button(action: {
                    showServerConnectionView = true
                }) {
                    Text("Go to Server Connection Page")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Text("3. On the Server Connection Page:")
                    .fontWeight(.semibold)
                Text("• Enter the IP address you found")
                Text("• Click the 'Connect' button")
                
                Text("4. Your connection will be established.")
                    .fontWeight(.semibold)
            }
            .textSelection(.enabled)
        }
    }
}

struct GuideSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical)
    }
}
