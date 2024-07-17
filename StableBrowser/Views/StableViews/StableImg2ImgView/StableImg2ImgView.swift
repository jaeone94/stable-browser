import SwiftUI
import RealmSwift

struct StableImg2ImgView: View {
    @StateObject var viewModel = StableSettingViewModel.shared
    @StateObject var browserViewModel = BrowserViewModel.shared
    
    // For resizing image
    @State internal var width: CGFloat = StableSettingViewModel.shared.width
    @State internal var height: CGFloat = StableSettingViewModel.shared.height
    @State private var maxImageSize: CGFloat = 2400
    
    // Alert
    @State internal var showAlert = false
    @State internal var alertType : AlertType = .resize
    
    // Image
    @State internal var baseImage: UIImage = StableSettingViewModel.shared.baseImage {
        didSet {
            StableSettingViewModel.shared.baseImage = self.baseImage
        }
    }
    @State internal var maskImage: UIImage? = StableSettingViewModel.shared.maskImage {
        didSet {
            StableSettingViewModel.shared.maskImage = self.maskImage
        }
    }
    @State internal var resultImages: [ResultImage] = StableSettingViewModel.shared.img2imgResultImages {
        didSet {
            StableSettingViewModel.shared.img2imgResultImages = self.resultImages
        }
    }
    
    @State internal var selectedIndex = 0
    @State internal var canInject: Bool = false

    // For Generate Image
    @State private var isInpaintMode: Bool = true
    @State internal var resizeScale: Double = 1
    @State internal var prompt: String = ""
    @State internal var negativePrompt: String = ""
    @State private var batchCount: Int = 1
    @State private var localStyles: [LocalPromptStyle]?

    // For progress bar
    @State private var timer: Timer?
    @State internal var isProgressing: Bool = false
    @State internal var progress: Float = 0.0
    
    @State private var isConnected = false
    
    @State private var triggerRedraw = false

    @State private var resizeTo8x: Bool = true
    
    @State internal var uploadImagePopupVisible: Bool = false
    
    @State internal var isStopping = false

    // Alert type
    enum AlertType {
        case resize
        case noMaskImage // Inpaint mode without mask image
    }
    
    
    func importBaseImage(baseImage: UIImage) {
        self.width = baseImage.size.width
        self.height = baseImage.size.height
        self.baseImage = baseImage
        DispatchQueue.main.async {
            self.isImageTooLarge() {
                rst in
                if rst {
                    self.resizeImage()
                    self.alertType = .resize
                    self.showAlert = true
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    BaseImageSection(parent: self, baseImage: $baseImage, maskImage: $maskImage, resizeScale: $resizeScale, width: $width, height: $height, isInpaintMode: $isInpaintMode, uploadImageSheetVisible: $uploadImagePopupVisible)
                    
                    if isConnected {
                        Section(isProgressing ? "Generating..." : "Img2Img") {
                            if isProgressing {
                                // stop button
                                Button(isStopping ? "Stopping a task..." : "Stop generating") {
                                    isStopping = true
                                    if let api = viewModel.webUIApi {
                                        Task {
                                            await api.interrupt()
                                            await api.skip()
                                        }
                                    }
                                }.font(.title3).foregroundColor(.red)
                                HStack {
                                    ProgressView(value: progress, total: 1)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .padding(.vertical, 10)
                                    Spacer()
                                    // Progress percentage
                                    Text("\(Int(progress * 100))%")
                                        .font(.title3)
                                        .padding(.trailing, 10)
                                }
                            }else {
                                GenerateImageButton(batchCount: $batchCount, doGenerate: doImg2Img)
                                // Batch Count
                                Stepper(value: $batchCount, in: 1...10) {
                                    Text("Batch Count: \(batchCount)")
                                }
                            }
                        }
                        
                        if resultImages.count > 0 && !isProgressing {
                            ResultSection(parent: self, resultImages: resultImages, selectedIndex: $selectedIndex)
                        }
                        
                        
                        
                        Img2ImgModeSection(isInpaintMode: $isInpaintMode, viewModel: viewModel)
                        GenerateOptionsSection(parent: self, viewModel: viewModel)
                    }else {
                        // Server connection required
                        Section(header: Text("Server connection required")) {
                            NavigationLink(destination: ServerConnectionView()) {
                                HStack {
                                    Spacer()
                                    Text("Connecting your own server").foregroundColor(.accentColor)
                                    Spacer()
                                }
                            }
                        }
                        .onAppear{
                            isConnected = viewModel.isConnected ?? false
                        }
                    }
                }
                .onAppear{
                    isConnected = viewModel.isConnected ?? false
                }
                .navigationBarTitle("IMAGE TO IMAGE", displayMode: .inline)
                .navigationBarItems(
                    trailing: NavigationLink(destination: StableSettingsView()) {
                        Image(systemName: "gear")
                    }
                )
            }.navigationViewStyle(.stack)
                .id(triggerRedraw)
                .background(Color(UIColor.secondarySystemBackground))
                .onAppear {
                    isImageTooLarge() {
                        rst in
                        if rst {
                            resizeImage()
                            alertType = .resize
                            showAlert = true
                        }
                    }
                }
                .onAppear (perform : UIApplication.shared.hideKeyboard)
                .onDisappear{
                    viewModel.isInpaintMode = isInpaintMode
                    saveSettingsToViewModel()
                }
                .alert(isPresented: $showAlert) {
                    switch alertType {
                    case .resize:
                        return Alert(title: Text("Image resized"), message: Text("The image has been automatically resized to \(Int(width * baseImage.scale)) x \(Int(height * baseImage.scale)) for improve perfomance."), dismissButton: .default(Text("OK")))
                    case .noMaskImage:
                        return Alert(title: Text("No Mask Image"), message: Text("Mask image is required in inpaint mode. Please make mask image in 'Edit Image' menu"), dismissButton: .default(Text("OK")))
                    }
                }.onAppear{
                    if browserViewModel.imageId != nil {
                        canInject = true
                    }
                    
                    self.isInpaintMode = viewModel.isInpaintMode
                }
            
            ZStack {
                if uploadImagePopupVisible {
                    Rectangle().fill(Color.black.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    
                    ImagePickerView(parent: self)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut, value: uploadImagePopupVisible)
        }
    }

    func InjectImage() {
        OverlayService.shared.showOverlaySpinner()
        MenuService.shared.switchMenu(to: MenuService.shared.menus[0])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            browserViewModel.imageForInject = resultImages[selectedIndex].image
        }
    }

 
    func doImg2Img() {
        saveSettingsToViewModel()
        
        // Inpaint mode without mask image
        if isInpaintMode && maskImage == nil {
            alertType = .noMaskImage
            showAlert = true
            return
        }

        if isInpaintMode {
            if let maskImage = self.maskImage{
                let resizedMaskImage = maskImage.resizeTargetImageToMatchSource(src: baseImage)
                if let croppedBaseImage = baseImage.cropToNearest8Multiple(),
                   let croppedMaskImage = resizedMaskImage.cropToNearest8Multiple() {
                    self.baseImage = croppedBaseImage
                    self.maskImage = croppedMaskImage
                }
            }
        }

        // Start Timer
        if let api = viewModel.webUIApi {
            withAnimation{
                self.isProgressing = true
            }
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                Task {
                    if let progress = await api.getProgress() {
                        DispatchQueue.main.async {
                            withAnimation{
                                self.progress = Float(progress.progress)
                            }
                        }
                    }
                }
            }
        }
        selectedIndex = 0
        Task { await generateImage() }
                
    }
    
    func generateImage() async {
        let sizeInPixels = convertCGSizeToPixel(size: baseImage.size, resizeScale: CGFloat(resizeScale))
        print(sizeInPixels)
        let intWidth = Int(sizeInPixels.width)
        let intHeight = Int(sizeInPixels.height)

        let selectedPromptStyles = viewModel.selectedPromptStyles // [String]
            
        let (promptTemp, negativePromptTemp) = await withCheckedContinuation { continuation in
                preparePrompts(selectedPromptStyles: selectedPromptStyles) { (prompt, negativePrompt) in
                    continuation.resume(returning: (prompt, negativePrompt))
                }
            }

        if let api = viewModel.webUIApi {            
            Task {           
                let softInpaintingArgs: [String: Any] = [
                    "Soft inpainting": viewModel.softInpainting,
                    "Schedule bias": viewModel.scheduleBias,
                    "Preservation strength": viewModel.preservationStrength,
                    "Transition contrast boost": viewModel.transitionContrastBoost,
                    "Mask influence": 0,
                    "Difference threshold": 0.5,
                    "Difference contrast": 2,
                ]

                let alwaysonScripts: [String: [String: Any]] = [
                    "soft inpainting": [
                        "args": [softInpaintingArgs]
                    ]
                ]
                
                let webUIApiResult = await api.img2img(
                    mode: isInpaintMode ? .inpaint : .normal
                   , initImages: [baseImage]
                   , mask: maskImage
                   , maskBlur: viewModel.maskBlur
                   , inpaintingFill: viewModel.inpaintingFill
                   , inpaintFullRes: viewModel.inpaintFullRes != 0
                   , inpaintFullResPadding: viewModel.inpaintFullResPadding
                   , inpaintingMaskInvert: viewModel.maskInvert
                   , resizeMode: viewModel.resizeMode
                   , denoisingStrength: viewModel.denoisingStrength
                   , prompt: promptTemp
                   , negativePrompt: negativePromptTemp
                   , styles: []
                   , seed: viewModel.seed
                   , samplerName: viewModel.selectedSampler
                   , batchSize: batchCount
                   , steps: viewModel.steps
                   , cfgScale: viewModel.cfgScale
                   , width: intWidth
                   , height: intHeight
                   , overrideSettings: [
                    "sd_model_checkpoint": viewModel.selectedSDModel,
                    "CLIP_stop_at_last_layers": viewModel.clipSkip,
                    "sd_vae": viewModel.selectedSdVae
                   ]
                   , sendImages: true
                   , saveImages: false
                   , alwaysonScripts: viewModel.isInpaintMode && viewModel.softInpainting ? alwaysonScripts : [:]
                )
                
                timer?.invalidate()
                timer = nil
                                
                let result = webUIApiResult
                if let result = result {
                    isStopping = false
                    var resultImages: [ResultImage] = []
                    let imageCount = result.images.count

                    if imageCount > 0 {
                        let jsonData = try! JSONSerialization.data(withJSONObject: result.json, options: .prettyPrinted)
                        let jsonObject = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
                        let infoString = jsonObject["info"] as! String
                        let infoData = infoString.data(using: .utf8)!
                        let info = try! JSONSerialization.jsonObject(with: infoData, options: []) as! [String: Any]
                        
                        let prompt = info["prompt"] as? String ?? ""
                        let negativePrompt = info["negative_prompt"] as? String ?? ""
                        let sdModelName = info["sd_model_name"] as? String ?? ""
                        let samplerName = info["sampler_name"] as? String ?? ""
                        let clipSkip = info["clip_skip"] as? Int ?? -1
                        let steps = info["steps"] as? Int ?? -1
                        let cfgScale = info["cfg_scale"] as? Double ?? -1
                        let denoisingStrength = info["denoising_strength"] as? Double ?? -1
                        let seed = info["seed"] as? Int ?? -1
                        let subseed = info["subseed"] as? Int ?? -1
                        let subseedStrength = info["subseed_strength"] as? Double ?? -1
                        let width = info["width"] as? Int ?? -1
                        let height = info["height"] as? Int ?? -1
                        let sdVaeName = info["sd_vae_name"] as? String
                        let restoreFaces = info["restore_faces"] as? Int ?? -1

                        for index in 0..<imageCount {
                            let newInfo = [
                                "prompt": prompt,
                                "negative_prompt": negativePrompt,
                                "sd_model_name": sdModelName,
                                "sampler_name": samplerName,
                                "clip_skip": clipSkip,
                                "steps": steps,
                                "cfg_scale": cfgScale,
                                "denoising_strength": denoisingStrength,
                                "seed": seed + index,
                                "subseed": subseed + index,
                                "subseed_strength": subseedStrength,
                                "width": width,
                                "height": height,
                                "sd_vae_name": sdVaeName ?? "null",
                                "restore_faces": restoreFaces
                            ]
                            let image = result.images[index]
                            let seed = newInfo["seed"] as! Int
                            let subSeed = newInfo["subseed"] as! Int
                            let resultImage = ResultImage(image: image, info: newInfo, seed: seed, subSeed: subSeed)
                            resultImages.append(resultImage)                            
                        }
                    }
                                                            
                    withAnimation{
                        self.resultImages = resultImages
                        self.isProgressing = false
                        self.progress = 0
                    }                    
                }
            }
        }
    }
    
    
    func preparePrompts(selectedPromptStyles: [String], completion: @escaping (String, String) -> Void) {
        var promptTemp = self.prompt
        var negativePromptTemp = self.negativePrompt
                
        DispatchQueue.main.async {
            let realm = try! Realm()
            let localStyles = realm.objects(LocalPromptStyle.self)
            
            if selectedPromptStyles.count > 0 {
                for style in localStyles {
                    if selectedPromptStyles.contains(style.name ?? "") {
                        if let prompt = style.prompt, !prompt.isEmpty {
                            if promptTemp.isEmpty {
                                promptTemp = prompt
                            } else {
                                promptTemp += (", " + prompt)
                            }
                        }
                        if let negative_prompt = style.negative_prompt, !negative_prompt.isEmpty {
                            if negativePromptTemp.isEmpty {
                                negativePromptTemp = negative_prompt
                            } else {
                                negativePromptTemp += (", " + negative_prompt)
                            }
                        }
                    }
                }
            }
            completion(promptTemp, negativePromptTemp)
        }
    }

    func convertCGSizeToPixel(size: CGSize, resizeScale: CGFloat) -> CGSize {
        return CGSize(width: Int(size.width * resizeScale * baseImage.scale), height: Int(size.height * resizeScale * baseImage.scale))
    }
    
    func updateSettingsFromViewModel() {
        // Update @State properties from ViewModel
    }
    
    func saveSettingsToViewModel() {
        // Save @State properties to ViewModel
        viewModel.saveCurrentSettings()
    }
    
    func isImageTooLarge(completion: @escaping (Bool) -> Void) {
        // get image size in pixels
        let sizeInPixels = convertCGSizeToPixel(size: baseImage.size, resizeScale: 1)
        let maxImageSize = maxImageSize
        completion(sizeInPixels.width > maxImageSize || sizeInPixels.height > maxImageSize)
    }
    
    func resizeImage() {
        // get image size in pixels
        let sizeInPixels = convertCGSizeToPixel(size: baseImage.size, resizeScale: CGFloat(1))
        
        // get the maximum pixel count of the image
        let maxPixel = max(sizeInPixels.width, sizeInPixels.height)
        
        // get the scale to resize the image
        let scale = maxImageSize / maxPixel
        
        print(baseImage.scale)
        
        // get the target size of the image
        // calculate the target size
        _ = UIScreen.main.scale
        let targetSize = CGSize(width: baseImage.size.width * scale, height: baseImage.size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetSize.width, height: targetSize.height))
        let resizedImage = renderer.image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        importBaseImage(baseImage: resizedImage)
    }
}



struct GenerateImageButton: View {
//    var parent: BrowserView
    @Binding var batchCount: Int
    var doGenerate: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button("Generate Image") {
                    doGenerate()
                }.font(.title3).foregroundColor(.accentColor)
                Spacer()
            }            
        }
    }
}

struct ResultSection: View {
    var parent: StableImg2ImgView
    var resultImages: [ResultImage]
    @Binding var selectedIndex: Int
    @State internal var resultSectionId = UUID()

    var body: some View {
        Section(header: Text("Result Images")) {
            if !resultImages.isEmpty {
                let firstImage = resultImages[0].image
                let imageWidth = firstImage.size.width
                let imageHeight = firstImage.size.height
                let aspectRatio = imageWidth / imageHeight
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                let maxHeight = screenHeight * 0.6 // 60% of screen height
                let calculatedHeight = min(screenWidth / aspectRatio, maxHeight)
                
                TabView(selection: $selectedIndex) {
                    ForEach(resultImages.indices, id: \.self) { index in
                        NavigationLink(destination: ResultImageView(img2imgView: parent, parent: self, resultImages: resultImages, sourceImage: parent.baseImage, selectedImageIndex: $selectedIndex)) {
                            Image(uiImage: resultImages[index].image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: calculatedHeight)
                .id(resultSectionId)
            }
            
            if parent.canInject && BrowserViewModel.shared.imageId != nil {
                HStack {
                    Spacer()
                    Button("Inject into Browser") {
                        parent.InjectImage()
                    }.font(.title3).foregroundColor(.accentColor)
                    Spacer()
                }
            }
        }
    }
}

struct Img2ImgModeSection: View {
    @Binding var isInpaintMode: Bool
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        Section(header: Text("INPAINT MODE")) {
            Toggle(isOn: $isInpaintMode.animation()) {
                Text("Inpaint mode")
            }
            
            if isInpaintMode {
                InpaintOptionsSection(viewModel: viewModel)
            }
        }
    }
}

struct InpaintOptionsSection: View {
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        DisclosureGroup("Inpaint options") {
            MaskBlurPicker(maskBlur: $viewModel.maskBlur)
            InpaintingFillPicker(inpaintingFill: $viewModel.inpaintingFill)
            MaskInvertPicker(maskInvert: $viewModel.maskInvert)
            InpaintFullResPicker(inpaintFullRes: $viewModel.inpaintFullRes)
            InpaintFullResPaddingSlider(inpaintFullResPadding: $viewModel.inpaintFullResPadding)
            
            Toggle(isOn: $viewModel.softInpainting) {
                Text("Soft Inpainting")
            }
            
            if viewModel.softInpainting {
                SoftInpaintingSection(viewModel: viewModel)
            }
        }
    }
}

struct SoftInpaintingSection: View {
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Schedule Bias")
                Spacer()
                Text("\(viewModel.scheduleBias, specifier: "%.1f")")
            }
            Slider(value: $viewModel.scheduleBias, in: 0...8, step: 0.1)
            
            HStack {
                Text("Preservation Strength")
                Spacer()
                Text("\(viewModel.preservationStrength, specifier: "%.2f")")
            }
            Slider(value: $viewModel.preservationStrength, in: 0...8, step: 0.05)
            
            HStack {
                Text("Transition Contrast Boost")
                Spacer()
                Text("\(viewModel.transitionContrastBoost, specifier: "%.2f")")
            }
            Slider(value: $viewModel.transitionContrastBoost, in: 1...32, step: 0.05)
        }
    }
}

struct GenerateOptionsSection: View {
    var parent: StableImg2ImgView
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        Section(header: Text("Generation options")) {
            PromptsSection(parent: self, viewModel: viewModel)
            SamplingOptionsSection(viewModel: viewModel)
        }
    }
}

struct PromptsSection: View {
    var parent: GenerateOptionsSection
    @ObservedObject var viewModel: StableSettingViewModel
    
    @State var prompt: String = ""
    @State var negativePrompt: String = ""
    
    var body: some View {
        DisclosureGroup("Prompts") {
            VStack(alignment: .leading){
                HStack {
                    Text("Prompt")
                    Spacer()
                }
                TextEditor(text: $prompt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    .onChange(of: prompt) {
                        oldValue, newValue in
                        parent.parent.prompt = newValue
                    }
            }
            
            VStack(alignment: .leading){
                HStack {
                    Text("Negative Prompt")
                    Spacer()
                }                
                TextEditor(text: $negativePrompt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    .onChange(of: negativePrompt) {
                        oldValue, newValue in
                        parent.parent.negativePrompt = newValue
                    }
            }
            
            HStack {
                Text("Styles")
                Spacer()
                let first = viewModel.selectedPromptStyles.first
                let count = viewModel.selectedPromptStyles.count
                let isMoreThanOne = count > 1
                Text(isMoreThanOne ? "\(count) styles" : first ?? "")
                    .lineLimit(1)
                    .padding(.leading, 20)
                NavigationLink(destination: StableStyleSelectView(viewModel: viewModel, selectedPromptStyles: $viewModel.selectedPromptStyles, localPromptStyles: $viewModel.localPromptStyles)) {
                    EmptyView()
                }
            }
            
            
            // restore Face Toggle button
            Toggle(isOn: $viewModel.restoreFaces) {
                Text("Restore Face")
            }
        }
    }
}


struct SamplingOptionsSection: View {
    @ObservedObject var viewModel: StableSettingViewModel
    @State var isRandomSeed: Bool = false
    
    var body: some View {
        DisclosureGroup("Sampling options") {
            NavigationLink(destination: SamplerSettingView(parent: self, title: "Samplers", sampler: viewModel.selectedSampler, key: "samplers")) {
                HStack {
                    Text("Sampler")
                    Spacer()
                    Text(viewModel.selectedSampler)
                        .lineLimit(1)
                        .padding(.leading, 20)
                }
            }


            StepsPicker(steps: $viewModel.steps)
            ResizeModePicker(resizeMode: $viewModel.resizeMode)
            CfgScaleSlider(cfgScale: $viewModel.cfgScale)
            DenoisingStrengthSlider(denoisingStrength: $viewModel.denoisingStrength)
            // Toggle button for random seed, when the toggle button is on, set the seed to -1, otherwise, use a TextField to input the seed
            Toggle(isOn: $isRandomSeed.animation()) {
                Text("Random Seed")
            }.onChange(of: isRandomSeed) {
                oldValue, newValue in
                    viewModel.seed = -1
            }
            if !isRandomSeed {
                SeedTextField(seed: $viewModel.seed)
            }
        }
        .onAppear {
            isRandomSeed = viewModel.seed == -1
        }
    }
}
