import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var webViewModel: WebViewModel
    @State private var showServerGuide = false
    @State private var showModelInstallGuide = false
    @State private var showAppGuide = false
    let contactURL = "https://github.com/jaeone94/stable-browser/wiki/Contact"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Welcome to StableBrowser")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
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
                    
                    Spacer(minLength: 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("For any inquiries, reports, bug notifications, or concerns regarding this app, please contact us through:")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        contactLink
                        
                        Text("We appreciate your feedback and are committed to improving your experience with our app.")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    Text("Enter a URL or search term in the address bar to start browsing.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .environmentObject(webViewModel)
    }
    
    var contactLink: some View {
        Button(action: {
            if let url = URL(string: contactURL) {
                UIApplication.shared.open(url)
            }
        }) {
            Text("Contact URL")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .underline()
        }
    }
}
