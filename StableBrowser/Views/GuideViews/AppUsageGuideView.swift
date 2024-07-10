import SwiftUI

struct AppUsageGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("App Usage Guide")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                guideSection(title: "Menu Navigation",
                             description: "Switch between different app functions using the menu selector.",
                             gifName: "menu_navigation",
                             systemImage: "sidebar.left")
                
                guideSection(title: "Image Generation",
                             description: "Adjust prompts and settings in txt2img or img2img view, generate images, and save to gallery.",
                             gifName: "image_generation",
                             systemImage: "wand.and.stars")
                
                guideSection(title: "Gallery Usage",
                             description: "View generated images and their creation settings in the gallery.",
                             gifName: "gallery_usage",
                             systemImage: "photo.on.rectangle.angled")
                
                guideSection(title: "Image Collection from Browser",
                             description: "Collect images from the browser to use as base images in img2img.",
                             gifName: "image_collection",
                             systemImage: "photo.fill.on.rectangle.fill")
                
                additionalTips
                
                copyrightNotice
            }
            .padding()
        }
        .navigationBarTitle("App Usage Guide", displayMode: .inline)
    }
    
    func guideSection(title: String, description: String, gifName: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(description)
                .font(.body)
            
            if NSDataAsset(name: gifName) != nil {
                GIFImage(name: gifName)
                    .frame(height: 650)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            } else {
                Text("GIF demonstration not available")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }
    
    var additionalTips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Additional Tips:")
                .font(.title3)
                .fontWeight(.bold)
            
            tipView(text: "Long press on an image in the browser to open the image selector.", systemImage: "hand.tap")
            tipView(text: "Use the 'Scan all Images' button to view all medium-sized images on a webpage.", systemImage: "photo.stack")
            tipView(text: "The 'Capture Screenshot' button allows you to use the current browser view as a base image.", systemImage: "camera.viewfinder")
            tipView(text: "In the gallery, tap on an image to view its generation settings.", systemImage: "info.circle")
        }
    }
    
    func tipView(text: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(text)
        }
    }
    
    var copyrightNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Important Copyright Notice")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("When collecting images, pictures, or any other content from the internet, it is crucial to adhere to copyright laws. Ensure you have the necessary rights or permissions before using any copyrighted material. Unauthorized use of copyrighted content may result in legal consequences.")
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(10)
        }
        .padding(.top, 20)
    }
}
