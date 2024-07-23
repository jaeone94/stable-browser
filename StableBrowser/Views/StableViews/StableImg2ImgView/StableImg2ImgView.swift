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
    @State internal var resizeScale: Double = 1
    @State private var batchCount: Int = 1
    
    @State private var isConnected = false
    
    @State private var triggerRedraw = false

    @State private var resizeTo8x: Bool = true
    
    @State internal var uploadImagePopupVisible: Bool = false

    // Alert type
    enum AlertType {
        case resize
        case noMaskImage // Inpaint mode without mask image
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    BaseImageSection(parent: self, baseImage: $baseImage, maskImage: $maskImage, resizeScale: $resizeScale, width: $width, height: $height, isInpaintMode: $viewModel.isInpaintMode, uploadImageSheetVisible: $uploadImagePopupVisible)
                    
                    if isConnected {
                        Img2ImgModeSection(isInpaintMode: $viewModel.isInpaintMode, viewModel: viewModel)
                        GenerateOptionsSection(parent: self, viewModel: viewModel)
                        
                        Section("IMG2IMG GENERATE") {
                            GenerateImageButton(batchCount: $batchCount, doGenerate: doImg2Img)
                            // Batch Count
                            Stepper(value: $batchCount, in: 1...10) {
                                Text("Batch Size: \(batchCount)")
                            }
                        }
                        
                    } else {
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
                    viewModel.saveCurrentSettings()
                }
                .alert(isPresented: $showAlert) {
                    switch alertType {
                    case .resize:
                        return Alert(title: Text("Image resized"), message: Text("The image has been automatically resized to \(Int(width * baseImage.scale)) x \(Int(height * baseImage.scale)) for improve performance."), dismissButton: .default(Text("OK")))
                    case .noMaskImage:
                        return Alert(title: Text("No Mask Image"), message: Text("Mask image is required in inpaint mode. Please make mask image in 'Edit Image' menu"), dismissButton: .default(Text("OK")))
                    }
                }.onAppear{
                    if browserViewModel.imageId != nil {
                        canInject = true
                    }
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
        .onChange(of: viewModel.baseImageFromResult) { oldValue, newValue in
            if newValue.size.width != 0 {
                self.importBaseImage(baseImage: newValue)
                self.maskImage = nil
                self.resizeScale = 1
            }
        }
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

    func InjectImage() {
        OverlayService.shared.showOverlaySpinner()
        MenuService.shared.switchMenu(to: MenuService.shared.menus[0])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            browserViewModel.imageForInject = resultImages[selectedIndex].image
        }
    }
 
    func doImg2Img() {
        // Inpaint mode without mask image
        if viewModel.isInpaintMode && maskImage == nil {
            alertType = .noMaskImage
            showAlert = true
            return
        }

        if viewModel.isInpaintMode {
            if let maskImage = self.maskImage{
                let resizedMaskImage = maskImage.resizeTargetImageToMatchSource(src: baseImage)
                if let croppedBaseImage = baseImage.cropToNearest8Multiple(),
                   let croppedMaskImage = resizedMaskImage.cropToNearest8Multiple() {
                    self.baseImage = croppedBaseImage
                    self.maskImage = croppedMaskImage
                }
            }
        }

        selectedIndex = 0
        Task { await generateImage() }
    }
    
    func generateImage() async {
        let sizeInPixels = convertCGSizeToPixel(size: baseImage.size, resizeScale: CGFloat(resizeScale))
        let intWidth = Int(sizeInPixels.width)
        let intHeight = Int(sizeInPixels.height)

        let (promptTemp, negativePromptTemp) = await withCheckedContinuation { continuation in
                preparePrompts(selectedPromptStyles: viewModel.imgSelectedPromptStyles) { (prompt, negativePrompt) in
                    continuation.resume(returning: (prompt, negativePrompt))
                }
            }
               
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
                
        let imgContext = Img2ImgGenerationContext(
            mode: viewModel.isInpaintMode ? .inpaint : .normal,
            initImages: [baseImage],
            mask: maskImage,
            maskBlur: viewModel.maskBlur,
            inpaintingFill: viewModel.inpaintingFill,
            inpaintFullRes: viewModel.inpaintFullRes != 0,
            inpaintFullResPadding: viewModel.inpaintFullResPadding,
            inpaintingMaskInvert: viewModel.maskInvert,
            resizeMode: viewModel.resizeMode,
            denoisingStrength: viewModel.denoisingStrength,
            prompt: promptTemp,
            negativePrompt: negativePromptTemp,
            styles: [],
            seed: viewModel.imgSeed,
            samplerName: viewModel.imgSelectedSampler,
            scheduler: viewModel.imgSelectedScheduler,
            batchSize: batchCount,
            steps: viewModel.imgSteps,
            cfgScale: viewModel.imgCfgScale,
            width: intWidth,
            height: intHeight,
            overrideSettings: [
                "sd_model_checkpoint": viewModel.selectedSDModel,
                "CLIP_stop_at_last_layers": viewModel.clipSkip,
                "sd_vae": viewModel.selectedSdVae
            ],
            sendImages: true,
            saveImages: false,
            alwaysonScripts: viewModel.isInpaintMode && viewModel.softInpainting ? alwaysonScripts : [:]
        )
        
        ContextQueueManager.shared.addContext(imgContext)
    }
    
    func preparePrompts(selectedPromptStyles: [String], completion: @escaping (String, String) -> Void) {
        var promptTemp = viewModel.imgPrompt
        var negativePromptTemp = viewModel.imgNegativePrompt
                
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
        
        // get the target size of the image
        let targetSize = CGSize(width: baseImage.size.width * scale, height: baseImage.size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetSize.width, height: targetSize.height))
        let resizedImage = renderer.image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        importBaseImage(baseImage: resizedImage)
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
        MaskBlurPicker(maskBlur: $viewModel.maskBlur)
        InpaintingFillPicker(inpaintingFill: $viewModel.inpaintingFill)
        MaskInvertPicker(maskInvert: $viewModel.maskInvert)
        InpaintFullResPicker(inpaintFullRes: $viewModel.inpaintFullRes)
        if viewModel.inpaintFullRes == 1 {
            InpaintFullResPaddingSlider(inpaintFullResPadding: $viewModel.inpaintFullResPadding)
        }
              
        DisclosureGroup("Soft Inpainting") {
            Toggle(isOn: $viewModel.softInpainting.animation()) {
                Text("Use Soft Inpainting")
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
        Section(content: {
            PromptsSection(parent: self, viewModel: viewModel)
        }, header: {
            Text("PROMPTS")
        })
        Section(content: {
            SamplingOptionsSection(viewModel: viewModel)
        }, header: {
            Text("SAMPLING OPTIONS")
        })
    }
}

struct PromptsSection: View {
    var parent: GenerateOptionsSection
    @ObservedObject var viewModel: StableSettingViewModel
    @State var selectedLora: Lora? = nil
    @State var selectedPromptType: String = "positive"
    @State var loraStrength: Float32 = 1.0
    
    var body: some View {
        DisclosureGroup("Prompts") {
            VStack(alignment: .leading){
                HStack {
                    Text("Prompt")
                    Spacer()
                }
                TextEditor(text: $viewModel.imgPrompt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            }
            
            VStack(alignment: .leading){
                HStack {
                    Text("Negative Prompt")
                    Spacer()
                }
                TextEditor(text: $viewModel.imgNegativePrompt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            }
            
            DisclosureGroup("Loras") {
                ForEach(viewModel.loras, id: \.self) { lora in
                    Button {
                        if self.selectedLora == lora {
                            withAnimation {
                                self.selectedLora = nil
                            }
                        }else {
                            withAnimation {
                                self.selectedLora = lora
                            }
                        }
                    } label: {
                        Text(lora.name).tag(lora.id)
                            .foregroundColor(lora == self.selectedLora ? Color.accentColor : Color.primary)
                    }
                }
                
                if selectedLora != nil {
                    let strLoraStrength = String(format: "%.1f", loraStrength)
                    VStack {
                        Text("Strength : \(strLoraStrength)")
                        Slider(value: $loraStrength, in: 0.1...2, step: 0.1)
                    }
                    
                    HStack {
                        // Choose positive or negative prompt
                        Picker("Prompt Type", selection: $selectedPromptType) {
                            Text("Positive").tag("positive")
                            Text("Negative").tag("negative")
                        }
                    }
                    
                    Button {
                        if let lora = selectedLora {
                            if selectedPromptType == "positive" {
                                viewModel.imgPrompt += ", <lora:\(lora.name):\(strLoraStrength)>"
                            } else {
                                viewModel.imgNegativePrompt += ", <lora:\(lora.name):\(strLoraStrength)>"
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Append Lora")
                            Spacer()
                        }
                    }
                }
            }
            
            HStack {
                Text("Styles")
                Spacer()
                let first = viewModel.imgSelectedPromptStyles.first
                let count = viewModel.imgSelectedPromptStyles.count
                let isMoreThanOne = count > 1
                Text(isMoreThanOne ? "\(count) styles" : first ?? "")
                    .lineLimit(1)
                    .padding(.leading, 20)
                NavigationLink(destination: StableStyleSelectView(viewModel: viewModel, mode: .img2img, selectedPromptStyles: $viewModel.imgSelectedPromptStyles, localPromptStyles: $viewModel.localPromptStyles)) {
                    EmptyView()
                }
            }
            
            Toggle(isOn: $viewModel.imgRestoreFaces) {
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
            Picker("Sampler", selection: $viewModel.imgSelectedSampler) {
                ForEach(viewModel.samplers, id: \.self) { sampler in
                    Text(sampler).tag(sampler)
                }
            }
            
            Picker("Scheduler", selection: $viewModel.imgSelectedScheduler) {
                ForEach(viewModel.schedulers, id: \.self) { scheduler in
                    Text(scheduler).tag(scheduler as String?)
                }
            }


            StepsPicker(steps: $viewModel.imgSteps)
            ResizeModePicker(resizeMode: $viewModel.resizeMode)
            CfgScaleSlider(cfgScale: $viewModel.imgCfgScale)
            DenoisingStrengthSlider(denoisingStrength: $viewModel.denoisingStrength)
            
            Toggle(isOn: $isRandomSeed.animation()) {
                Text("Random Seed")
            }.onChange(of: isRandomSeed) { oldValue, newValue in
                viewModel.imgSeed = -1
            }
            if !isRandomSeed {
                SeedTextField(seed: $viewModel.imgSeed)
            }
        }
        .onAppear {
            isRandomSeed = viewModel.imgSeed == -1
        }
    }
}


struct GenerateImageButton: View {
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
