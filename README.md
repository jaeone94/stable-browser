# StableBrowser
<img
  src="StableBrowser/Resources/Images/appIcon.png"
  width="100"
  height="100"
/>

StableBrowser is an web browser application with integrated AI image generation capabilities. It combines traditional web browsing functionality with advanced features for AI-assisted image creation and manipulation.

This app uses the API in [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui) to generate images.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Components](#components)
- [License](#license)

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

## License
This project is licensed under the MIT License.

---

Stable Browser is built with SwiftUI and leverages the power of Stable Diffusion for AI image generation. For questions or support, please open an issue in the GitHub repository or contact me at jaeone.prt@gmail.com
