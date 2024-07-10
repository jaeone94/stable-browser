import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var webViewModel: WebViewModel
    @State private var showServerGuide = false
    @State private var showModelInstallGuide = false
    @State private var showAppGuide = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to StableBrowser")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Get started with these guides:")
                    .font(.headline)
                
                NavigationLink(destination: ServerInstallationGuideView(), isActive: $showServerGuide) {
                    Button(action: {
                        showServerGuide = true
                    }) {
                        HStack {
                            Image(systemName: "server.rack")
                            Text("WebUI Server Installation Guide")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                NavigationLink(destination: ModelInstallationGuideView(), isActive: $showModelInstallGuide) {
                    Button(action: { showModelInstallGuide = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Model Installation Guide")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                
                
                NavigationLink(destination: AppUsageGuideView(), isActive: $showAppGuide) {
                    Button(action: {
                        showAppGuide = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("App Usage Guide")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                Text("Enter a URL or search term in the address bar to start browsing.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .environmentObject(webViewModel)
    }
}
