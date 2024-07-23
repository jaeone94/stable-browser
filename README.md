<table style="border-collapse: collapse; border: none;">
  <tr style="border: none;">
    <td style="vertical-align: middle; border: none;">
      <a href="https://apps.apple.com/app/stablebrowser/id6502819190"><img src="StableBrowser/Resources/Images/appIcon.png" width="75" height="75" /></a>
    </td>
    <td style="vertical-align: middle; padding-left: 10px; border: none;">
      <h1 style="margin: 0;">StableBrowser</h1>
    </td>
  </tr>
</table>

StableBrowser is a web browser application with integrated AI image generation capabilities. It combines traditional web browsing functionality with advanced features for AI-assisted image creation and manipulation.

This app uses the API in [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui) to generate images.    
  
<a href="https://apps.apple.com/app/stablebrowser/id6502819190">
 <img
  src="https://github.com/user-attachments/assets/794cdd01-2731-498c-a4bf-442e21059d85"
  width="220"
  height="75"
  />
</a>
 

## Table of Contents
- [Contact](#contact)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Components](#components)
- [Beta Test](#beta-test)
- [Contribution](#contribution)
- [License](#license)

## Contact
For any inquiries, reports, bug notifications, or concerns regarding this app, please contact us at:  
### jaeone.prt@gmail.com
Alternatively, you can raise an issue on this page.  
### We appreciate your feedback and are committed to improving your experience with our app.

## Features

- Standard web browsing capabilities
- Integrated AI image generation using [A1111's Web UI API](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API)
- Image to Image (Img2Img) transformation
- Text to Image (Txt2Img) generation
- Gallery for managing generated images
- Using images from the web directly into Img2Img

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jaeone94/stable-browser.git
   cd stable-browser
   ```
2. Install dependencies (assuming you're using a package manager like CocoaPods or SPM):
    ```
    pod install
    ```
    This project uses the following third-party libraries:
   - [RealmSwift](https://github.com/realm/realm-swift) for local data persistence
   - [KeychainSwift](https://github.com/evgenyneu/keychain-swift) for secure storage of sensitive data

3. Open the `.xcworkspace` file in Xcode and build the project.

## Usage

1. Use the address bar to navigate web pages as you would in a standard browser.  
You can easily collect a base image to use for Image to Image.  
![image_collection](https://github.com/jaeone94/stable-browser/assets/89377375/74420c93-a2a9-4bfb-9f4f-3e349956e576)

2. Select the Img2Img or Txt2Img option from the menu.  
![menu_navigation](https://github.com/jaeone94/stable-browser/assets/89377375/62764299-00e1-45cb-aaee-2cd24a391ed4)

3. Set the image generation parameters, such as prompts, and then generate the image.  
![image_generation](https://github.com/jaeone94/stable-browser/assets/89377375/1ee1f3fd-1278-49c9-9ec4-fc71aacab560)

4. Use the Gallery to view and manage your generated images.  
![gallery_usage](https://github.com/jaeone94/stable-browser/assets/89377375/abb443ac-49d0-461a-b0cb-6795bd862d8c)

## Components

- `BrowserView`: Main view for web browsing functionality. Manages the overall layout and interaction with other components.
- `StableImg2ImgView`: Handles Image to Image transformations. Provides interface for uploading source images and setting transformation parameters.
- `StableTxt2ImgView`: Manages Text to Image generation. Offers text input and parameter configuration for AI image generation.
- `GalleryView`: Displays and manages generated images. Provides options for viewing, organizing, and exporting generated images.
- `StableSettingsView`: Allows customization of browser and AI settings. Manages user preferences and application configuration.
- `WebViewModel`: Manages web view state and interactions. Handles URL loading, navigation, and web content rendering.
- `BrowserViewModel`: Handles overall browser state and navigation. Manages tabs, bookmarks, and browsing history.
- `ImageViewModel`: Manages the state and operations related to AI-generated images.
- `StableSettingViewModel`: Handles the configuration and settings for the Stable Diffusion AI model.
- `AuthenticationService`: Manages user authentication and secure data storage using KeychainSwift.
- `PhotoManagementService`: Handles the storage and retrieval of images using RealmSwift.
- `WebUIApi`: Interfaces with the Stable Diffusion web UI for AI image generation tasks.

## Beta Test
Public beta test link: [https://testflight.apple.com/join/5R8Z9JyS](https://testflight.apple.com/join/5R8Z9JyS)  
You can access this link to try out new features under development. We are looking forward to your feedback on improvements.

## Contribution
If you wish to contribute to this app, please feel free to submit pull requests or issues. We welcome and appreciate your contributions.

## License
This project is licensed under the MIT License.

---

Stable Browser is built with SwiftUI and leverages the power of Stable Diffusion for AI image generation. For questions or support, please open an issue in the GitHub repository or contact me at jaeone.prt@gmail.com
