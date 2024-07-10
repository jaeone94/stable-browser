import SwiftUI
import RealmSwift
struct StableTxt2ImgView: View {
    @StateObject var viewModel = StableSettingViewModel.shared
    
    
    // For progress bar
    @State private var timer: Timer?
    @State internal var isProgressing: Bool = false
    @State internal var progress: Float = 0.0
    
    @State private var isConnected = false
    
    // txt2img specific options
    
    
    @State internal var resultImages: [ResultImage] = []
    @State internal var selectedIndex = 0
    @State internal var isStopping = false
    
    var body: some View {
        NavigationView {
            Form {
                if isConnected {
                    Section(isProgressing ? "Generating..." : "Txt2Img") {
                        if isProgressing {
                            Button(isStopping ? "Stopping a task..." : "Stop generating") {
                                isStopping = true
                                if let api = viewModel.webUIApi {
                                    Task {
                                        await api.interrupt()
                                        await api.skip()
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
                                // Display percentage using self.progress
                                Text("\(Int(progress * 100))%")
                                    .font(.title3)
                                    .padding(.trailing, 10)
                            }
                        } else {
                            GenerateImageButton(batchCount: $viewModel.txt2imgBatchCount, doGenerate: doTxt2Img)
                            Stepper(value: $viewModel.txt2imgBatchCount, in: 1...10) {
                                Text("Batch Count: \(viewModel.txt2imgBatchCount)")
                            }
                        }
                    }
                    
                    if resultImages.count > 0 && !isProgressing {
                        TextResultSection(parent: self, resultImages: resultImages, selectedIndex: $selectedIndex)
                    }
                    
                    Section(header: Text("Generation options")) {
                        TxtDimensionsSection(viewModel: viewModel)
                        TxtPromptsSection(viewModel: viewModel)
                        SamplingOptionsSection(viewModel: viewModel)
                        UpscalingSection(viewModel: viewModel)
                    }
                } else {
                    Section(header: Text("Server connection required")) {
                        NavigationLink(destination: ServerConnectionView()) {
                            HStack {
                                Spacer()
                                Text("Connecting your own server").foregroundColor(.accentColor)
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        isConnected = viewModel.isConnected ?? false
                    }
                }
            }
            .onAppear {
                isConnected = viewModel.isConnected ?? false
            }
            .navigationBarTitle("TEXT TO IMAGE", displayMode: .inline)
            .navigationBarItems(trailing: NavigationLink(destination: StableSettingsView()) {
                Image(systemName: "gear")
            })
        }.navigationViewStyle(.stack)
    }


    func doTxt2Img() {
        if let api = viewModel.webUIApi {
            withAnimation {
                self.isProgressing = true
            }
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                Task {
                    if let progress = await api.getProgress() {
                        DispatchQueue.main.async {
                            withAnimation {
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
        if let api = viewModel.webUIApi {
            Task {
                let (promptTemp, negativePromptTemp) = await withCheckedContinuation { continuation in
                    preparePrompts(selectedPromptStyles: viewModel.selectedPromptStyles) { (prompt, negativePrompt) in
                        continuation.resume(returning: (prompt, negativePrompt))
                    }
                }

                let webUIApiResult = await api.txt2img(
                    enable_hr: viewModel.txt2imgEnableHR,
                    denoising_strength: viewModel.txt2imgDenoisingStrength,
                    firstphase_width: 0,
                    firstphase_height: 0,
                    hr_scale: viewModel.txt2imgHrScale,
                    hr_upscaler: viewModel.txt2imgHrUpscaler,
                    hr_second_pass_steps: viewModel.txt2imgHrSecondPassSteps,
                    hr_resize_x: viewModel.txt2imgHrResizeX,
                    hr_resize_y: viewModel.txt2imgHrResizeY,
                    prompt: promptTemp,
                    styles: viewModel.selectedPromptStyles,
                    seed: viewModel.seed,
                    subseed: -1,
                    subseed_strength: 0.0,
                    seed_resize_from_h: 0,
                    seed_resize_from_w: 0,
                    sampler_name: viewModel.selectedSampler,
                    batch_size: viewModel.txt2imgBatchCount,
                    n_iter: 1,
                    steps: viewModel.steps,
                    cfg_scale: viewModel.cfgScale,
                    width: viewModel.txt2imgWidth,
                    height: viewModel.txt2imgHeight,
                    restore_faces: viewModel.restoreFaces,
                    tiling: false,
                    do_not_save_samples: false,
                    do_not_save_grid: false,
                    negative_prompt: negativePromptTemp,
                    eta: 1.0,
                    s_churn: 0.0,
                    s_tmax: 0.0,
                    s_tmin: 0.0,
                    s_noise: 1.0,
                    override_settings: [
                        "sd_model_checkpoint": viewModel.selectedSDModel,
                        "CLIP_stop_at_last_layers": viewModel.clipSkip,
                        "sd_vae": viewModel.selectedSdVae
                    ],
                    override_settings_restore_afterwards: true,
                    script_args: nil,
                    script_name: nil,
                    send_images: true,
                    save_images: false,
                    alwayson_scripts: [:],
                    sampler_index: nil,
                    use_deprecated_controlnet: false,
                    use_async: false
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
                        let seed = info["seed"] as? Int ?? -1
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
                                "seed": seed + index,
                                "width": width,
                                "height": height,
                                "sd_vae_name": sdVaeName ?? "null",
                                "restore_faces": restoreFaces
                            ]
                            let image = result.images[index]
                            let seed = newInfo["seed"] as! Int
                            let resultImage = ResultImage(image: image, info: newInfo, seed: seed, subSeed: 0)
                            resultImages.append(resultImage)
                        }
                    }
                    
                    withAnimation {
                        self.resultImages = resultImages
                        self.isProgressing = false
                        self.progress = 0
                    }
                }
            }
        }
    }
    
    func preparePrompts(selectedPromptStyles: [String], completion: @escaping (String, String) -> Void) {
        var promptTemp = viewModel.txt2imgPrompt
        var negativePromptTemp = viewModel.txt2imgNegativePrompt
                
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
}



struct TxtPromptsSection: View {
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        DisclosureGroup("Prompts") {
            VStack(alignment: .leading){
                HStack {
                    Text("Prompt")
                    Spacer()
                }
                TextEditor(text: $viewModel.txt2imgPrompt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            }
            
            VStack(alignment: .leading){
                HStack {
                    Text("Negative Prompt")
                    Spacer()
                }
                TextEditor(text: $viewModel.txt2imgNegativePrompt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
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
            
            Toggle(isOn: $viewModel.restoreFaces) {
                Text("Restore Face")
            }
        }
    }
}


struct TextResultSection: View {
    var parent: StableTxt2ImgView
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
                let maxHeight = screenHeight * 0.6 // 60% of the screen height
                let calculatedHeight = min(screenWidth / aspectRatio, maxHeight)
                
                TabView(selection: $selectedIndex) {
                    ForEach(resultImages.indices, id: \.self) { index in
                        NavigationLink(destination: TextResultImageView(txt2imgView: parent, parent: self, resultImages: resultImages, selectedImageIndex: $selectedIndex)) {
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
        }
    }
}

struct TxtDimensionsSection: View {
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        DisclosureGroup("Dimensions") {
            HStack {
                Text("Width")
                Spacer()
                TextField("Width", value: $viewModel.txt2imgWidth, formatter: NumberFormatter())
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Text("Height")
                Spacer()
                TextField("Height", value: $viewModel.txt2imgHeight, formatter: NumberFormatter())
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}


struct UpscalingSection: View {
    @ObservedObject var viewModel: StableSettingViewModel
    
    var body: some View {
        DisclosureGroup("Upscaling") {
            Toggle("Enable High Resolution", isOn: $viewModel.txt2imgEnableHR)
            
            if viewModel.txt2imgEnableHR {
                VStack {
                    HStack {
                        Text("Scale")
                        Spacer()
                        Text("\(viewModel.txt2imgHrScale, specifier: "%.2f")")
                    }
                    Slider(value: $viewModel.txt2imgHrScale, in: 1...4, step: 0.1)
                    
                    Picker("Upscaler", selection: $viewModel.txt2imgHrUpscaler) {
                        ForEach(HiResUpscaler.allCases, id: \.self) { upscaler in
                            Text(upscaler.rawValue).tag(upscaler)
                        }
                    }
                    
                    HStack {
                        Text("Second Pass Steps")
                        Spacer()
                        TextField("Steps", value: $viewModel.txt2imgHrSecondPassSteps, formatter: NumberFormatter())
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    DenoisingStrengthSlider(denoisingStrength: $viewModel.txt2imgDenoisingStrength)
                }
            }
        }
    }
}

extension HiResUpscaler: CaseIterable {
    public static var allCases: [HiResUpscaler] {
        return [.none, .latent, .latentAntialiased, .latentBicubic, .latentBicubicAntialiased, .latentNearest, .latentNearestExact, .lanczos, .nearest, .esrgan4x, .ldsr, .scunetGAN, .scunetPSNR, .swinIR4x]
    }
}
