import SwiftUI
import SafariServices

struct ModelInstallationGuideView: View {
    @State private var showCivitAI = false
    @State private var showHuggingFace = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Model Installation Guide")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                guideContent
            }
            .padding()
        }
        .navigationBarTitle("Model Installation", displayMode: .inline)
        .sheet(isPresented: $showCivitAI) {
            SafariView(url: URL(string: "https://civitai.com/")!)
        }
        .sheet(isPresented: $showHuggingFace) {
            SafariView(url: URL(string: "https://huggingface.co/")!)
        }
    }
    
    var guideContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            stepView(number: 1, title: "Download a Model", content: {
                Text("Visit one of these websites to download your desired model:")
                Button("CivitAI") { showCivitAI = true }
                    .foregroundColor(.blue)
                Text("or")
                Button("Hugging Face") { showHuggingFace = true }
                    .foregroundColor(.blue)
            })
            
            stepView(number: 2, title: "Place the Model", content: {
                Text("After downloading, place the model file in the following directory:")
                Text("stable-diffusion-webui/models/Stable-diffusion")
                    .font(.system(size: 14, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            })
            
            stepView(number: 3, title: "Restart the Server", content: {
                Text("Restart your Stable Diffusion WebUI server to load the new model.")
                Text("The new model should now appear in the model selection dropdown in the WebUI.")
            })
            
            noteView
        }
    }
    
    func stepView(number: Int, title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step \(number): \(title)")
                .font(.title2)
                .fontWeight(.bold)
            content()
        }
        .padding(.bottom)
    }
    
    var noteView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note:")
                .font(.headline)
                .fontWeight(.bold)
            Text("Make sure to respect the licensing terms of any models you download and use.")
            Text("Some models may require additional setup or have specific usage instructions. Always check the model's documentation.")
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(10)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
