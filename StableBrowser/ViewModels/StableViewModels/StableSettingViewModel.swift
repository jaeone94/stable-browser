import Foundation
import RealmSwift

class StableSettingViewModel : ObservableObject {
    static let shared = StableSettingViewModel()
        
    var webUIApi: WebUIApi?
    @Published var isConnected : Bool?
    
    // option properties
    @Published var options: Options?
    @Published var sdModels: [SDModel] = []
    @Published var promptStyles: [PromptStyle] = []
    @Published var localPromptStyles: [LocalPromptStyle] = []
    @Published var samplers: [String] = []
    @Published var sdVAEs: [String] = []
    @Published var loras: [Lora] = []
    @Published var embeddings: [String] = []
    @Published var schedulers: [String] = []

    // Common Image generate properties
    @Published var selectedSDModel: String = ""
    @Published var clipSkip: Int = 1
    @Published var selectedSdVae: String = "Automatic"
    
    // Txt2Img specific properties
    @Published var txtSelectedPromptStyles: [String] = []
    @Published var txtSelectedSampler: String = "Euler a"
    @Published var txtSelectedScheduler: String = "automatic"
    @Published var txtSteps: Int = 20
    @Published var txtCfgScale: Double = 7.5
    @Published var txtSeed: Int = -1
    @Published var txtRestoreFaces: Bool = false
    @Published var txt2imgPrompt: String = ""
    @Published var txt2imgNegativePrompt: String = ""
    @Published var txt2imgBatchSize: Int = 1
    @Published var txt2imgWidth: Int = 512
    @Published var txt2imgHeight: Int = 512
    @Published var txt2imgDenoisingStrength: Double = 0.7
    @Published var txt2imgEnableHR: Bool = false
    @Published var txt2imgHrScale: Double = 2.0
    @Published var txt2imgHrUpscaler: HiResUpscaler = .latent
    @Published var txt2imgHrSecondPassSteps: Int = 0
    @Published var txt2imgHrResizeX: Int = 0
    @Published var txt2imgHrResizeY: Int = 0
    
    // Img2Img specific properties
    @Published var imgSelectedPromptStyles: [String] = []
    @Published var imgSelectedSampler: String = "Euler a"
    @Published var imgSelectedScheduler: String = "automatic"
    @Published var imgSteps: Int = 20
    @Published var imgCfgScale: Double = 7.5
    @Published var imgSeed: Int = -1
    @Published var imgRestoreFaces: Bool = false
    @Published var imgPrompt: String = ""
    @Published var imgNegativePrompt: String = ""
    @Published var width: CGFloat = 0
    @Published var height: CGFloat = 0
    @Published var resizeMode: Int = 0
    @Published var denoisingStrength: Double = 0.5
    
    // Inpaint properties
    @Published var isInpaintMode: Bool = false
    @Published var maskBlur: Int = 2
    @Published var inpaintingFill: Int = 1
    @Published var maskInvert: Int = 0
    @Published var inpaintFullRes: Int = 0
    @Published var inpaintFullResPadding: Int = 32
    @Published var softInpainting: Bool = false
    @Published var scheduleBias: Double = 1.0
    @Published var preservationStrength: Double = 0.5
    @Published var transitionContrastBoost: Double = 4.0
    
    // Img2Img properties
    @Published var baseImage: UIImage = UIImage() {
        didSet {
            self.width = self.baseImage.size.width
            self.height = self.baseImage.size.height
        }
    }
    
    @Published var maskImage: UIImage?
    @Published var baseImageFromResult: UIImage = UIImage() { // Separate properties for changing baseImage and maskImage simultaneously
        didSet {
            self.baseImage = self.baseImageFromResult
            self.maskImage = nil
        }
    }
    
    // maximum image size (width or height, whichever is larger)
    @Published var maxImageSize: Int = -1
    var maxImageSizeEnabled: Bool {
        get {
            return maxImageSize > 0
        }
    }

    // ResultImages
    @Published var txt2imgResultImages: [ResultImage] = []
    @Published var img2imgResultImages: [ResultImage] = []

    var connectedUrl: String?

    
    public func tryAutoConnectToServer() {
        guard let url = connectedUrl else {
            DispatchQueue.main.async {
                self.isConnected = false
            }
            print("Error: No connected URL available")
            return
        }
        
        let processedAddress = AddressProcessor.processAddress(url)
        let api = WebUIApi.shared
        
        do {
            try api.setConnectionProperties(processedAddress)
            
            Task {
                await connectToServer(api: api)
            }
        } catch ConnectionError.invalidAddress {
            print("Error: Invalid address format")
            setConnectionFailed()
        } catch ConnectionError.invalidURL {
            print("Error: Unable to create URL from address")
            setConnectionFailed()
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            setConnectionFailed()
        }
    }

    private func setConnectionFailed() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    private func connectToServer(api: WebUIApi) async {
        if let options = await api.getOptionsWithTimeout() {
            await MainActor.run {
                self.isConnected = true
                self.options = options
                self.webUIApi = api

                self.selectedSDModel = options.sd_model_checkpoint ?? ""
                
                Toast.shared.present(
                    title: "Server connected",
                    symbol: "checkmark.circle.fill",
                    isUserInteractionEnabled: true,
                    timing: .medium,
                    padding: 110
                )
            }
            
            // Call getSDModels function after successful server connection
            await getSDModels()
            await getPromptStyles()
            await getSamplers()
            await getSDVAE()
            await getLoras()
            await getScheduler()
            
        } else {
            await MainActor.run {
                self.isConnected = false
            }
        }
    }    
  
    public func saveCurrentSettings() {
        if isConnected ?? false {
            saveCommonSettings()
            saveTxt2ImgSettings()
            saveImg2ImgSettings()
        }
    }

    public func loadCurrentSettings() {
        loadLastUrl()
        loadCommonSettings()
        loadTxt2ImgSettings()
        loadImg2ImgSettings()
    }

    private func saveCommonSettings() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.clipSkip = self.clipSkip
                setting.selectedSdVae = self.selectedSdVae
                setting.localPromptStyles.removeAll()
                setting.localPromptStyles.append(objectsIn: self.localPromptStyles)
            } else {
                let newSetting = StableSettings()
                newSetting.clipSkip = self.clipSkip
                newSetting.selectedSdVae = self.selectedSdVae
                newSetting.localPromptStyles.append(objectsIn: self.localPromptStyles)
                realm.add(newSetting)
            }
        }
    }

    private func saveTxt2ImgSettings() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtSelectedSampler = self.txtSelectedSampler
                setting.txtSteps = self.txtSteps
                setting.txtCfgScale = self.txtCfgScale
                setting.txtSeed = self.txtSeed
                setting.txtRestoreFaces = self.txtRestoreFaces
                setting.txtSelectedPromptStyles.removeAll()
                setting.txtSelectedPromptStyles.append(objectsIn: self.txtSelectedPromptStyles)
                setting.txt2imgPrompt = self.txt2imgPrompt
                setting.txt2imgNegativePrompt = self.txt2imgNegativePrompt
                setting.txt2imgBatchCount = self.txt2imgBatchSize
                setting.txt2imgWidth = self.txt2imgWidth
                setting.txt2imgHeight = self.txt2imgHeight
                setting.txt2imgDenoisingStrength = self.txt2imgDenoisingStrength
                setting.txt2imgEnableHR = self.txt2imgEnableHR
                setting.txt2imgHrScale = self.txt2imgHrScale
                setting.txt2imgHrUpscaler = self.txt2imgHrUpscaler.rawValue
                setting.txt2imgHrSecondPassSteps = self.txt2imgHrSecondPassSteps
                setting.txt2imgHrResizeX = self.txt2imgHrResizeX
                setting.txt2imgHrResizeY = self.txt2imgHrResizeY
            }
        }
    }

    private func saveImg2ImgSettings() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgSelectedSampler = self.imgSelectedSampler
                setting.imgSteps = self.imgSteps
                setting.imgCfgScale = self.imgCfgScale
                setting.imgSeed = self.imgSeed
                setting.imgRestoreFaces = self.imgRestoreFaces
                setting.imgSelectedPromptStyles.removeAll()
                setting.imgSelectedPromptStyles.append(objectsIn: self.imgSelectedPromptStyles)
                setting.imgPrompt = self.imgPrompt
                setting.imgNegativePrompt = self.imgNegativePrompt
                setting.resizeMode = self.resizeMode
                setting.denoisingStrength = self.denoisingStrength
                setting.isInpaintMode = self.isInpaintMode
                setting.maskBlur = self.maskBlur
                setting.inpaintingFill = self.inpaintingFill
                setting.maskInvert = self.maskInvert
                setting.inpaintFullRes = self.inpaintFullRes
                setting.inpaintFullResPadding = self.inpaintFullResPadding
                setting.softInpainting = self.softInpainting
                setting.scheduleBias = self.scheduleBias
                setting.preservationStrength = self.preservationStrength
                setting.transitionContrastBoost = self.transitionContrastBoost
            }
        }
    }

    private func loadCommonSettings() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.clipSkip = setting.clipSkip
            self.selectedSdVae = setting.selectedSdVae
            self.localPromptStyles = Array(setting.localPromptStyles)
        }
    }

    private func loadTxt2ImgSettings() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtSelectedSampler = setting.txtSelectedSampler
            self.txtSteps = setting.txtSteps
            self.txtCfgScale = setting.txtCfgScale
            self.txtSeed = setting.txtSeed
            self.txtRestoreFaces = setting.txtRestoreFaces
            self.txtSelectedPromptStyles = Array(setting.txtSelectedPromptStyles)
            self.txt2imgPrompt = setting.txt2imgPrompt
            self.txt2imgNegativePrompt = setting.txt2imgNegativePrompt
            self.txt2imgBatchSize = setting.txt2imgBatchCount
            self.txt2imgWidth = setting.txt2imgWidth
            self.txt2imgHeight = setting.txt2imgHeight
            self.txt2imgDenoisingStrength = setting.txt2imgDenoisingStrength
            self.txt2imgEnableHR = setting.txt2imgEnableHR
            self.txt2imgHrScale = setting.txt2imgHrScale
            self.txt2imgHrUpscaler = HiResUpscaler(rawValue: setting.txt2imgHrUpscaler) ?? .latent
            self.txt2imgHrSecondPassSteps = setting.txt2imgHrSecondPassSteps
            self.txt2imgHrResizeX = setting.txt2imgHrResizeX
            self.txt2imgHrResizeY = setting.txt2imgHrResizeY
        }
    }

    private func loadImg2ImgSettings() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgSelectedSampler = setting.imgSelectedSampler
            self.imgSteps = setting.imgSteps
            self.imgCfgScale = setting.imgCfgScale
            self.imgSeed = setting.imgSeed
            self.imgRestoreFaces = setting.imgRestoreFaces
            self.imgSelectedPromptStyles = Array(setting.imgSelectedPromptStyles)
            self.imgPrompt = setting.imgPrompt
            self.imgNegativePrompt = setting.imgNegativePrompt
            self.resizeMode = setting.resizeMode
            self.denoisingStrength = setting.denoisingStrength
            self.isInpaintMode = setting.isInpaintMode
            self.maskBlur = setting.maskBlur
            self.inpaintingFill = setting.inpaintingFill
            self.maskInvert = setting.maskInvert
            self.inpaintFullRes = setting.inpaintFullRes
            self.inpaintFullResPadding = setting.inpaintFullResPadding
            self.softInpainting = setting.softInpainting
            self.scheduleBias = setting.scheduleBias
            self.preservationStrength = setting.preservationStrength
            self.transitionContrastBoost = setting.transitionContrastBoost
        }
    }

    
    func reBindOptions() async {
        if let options = await webUIApi?.getOptions() {
            await MainActor.run {
                self.options = options
            }
        }
    }
    
    func getSDModels() async {
        if let api = webUIApi {
            if let models = await api.getSDModels() {
                await MainActor.run {
                    self.sdModels = models
                }
            }
        }
    }

    func getPromptStyles() async {
        if let api = webUIApi {
            if let promptStyles = await api.getPromptStyles() {
                await MainActor.run {
                    self.promptStyles = promptStyles
                }
            }
        }
    }

    func getSamplers() async {
        if let api = webUIApi {
            if let samplers = await api.getSamplers() {
                await MainActor.run {
                    self.samplers = samplers
                }
            }
        }
    }
    
    func getScheduler() async {
        if let api = webUIApi {
            if let schedulers = await api.getSchedulers() {
                await MainActor.run {
                    self.schedulers = schedulers
                    if !schedulers.contains(self.txtSelectedScheduler) {
                        self.txtSelectedScheduler = "automatic"
                    }
                    if !schedulers.contains(self.imgSelectedScheduler) {
                        self.imgSelectedScheduler = "automatic"
                    }
                }
            }
        }
    }

    func getSDVAE() async {
        if let api = webUIApi {
            if let sdVAEs = await api.getSdVae() {
                await MainActor.run {
                    self.sdVAEs = sdVAEs
                    if !sdVAEs.contains(self.selectedSdVae) {
                        self.selectedSdVae = "Automatic"
                    }
                }
            }
        }
    }
    
    func setSDVAE(model: String) {
        self.selectedSdVae = model
        saveSdVae()
    }

    func getLoras() async {
        if let api = webUIApi {
            if let loras = await api.getLoras() {
                await MainActor.run {
                    self.loras = loras
                }
            }
        }
    }
    
    func getEmbeddings() async {
        if let api = webUIApi {
            if let embeddings = await api.getEmbeddings() {
                await MainActor.run {
                    self.embeddings = embeddings
                }
            }
        }
    }

    func setClipSkip(_ clipSkip: Double) {
        self.clipSkip = Int(clipSkip)
        saveClipSkip()
    }

    func setSDModel(model: String) {
        if let api = webUIApi {
            Task {
                if let options = self.options {
                    let rst = await api.utilSetModel(name: model, options: options)
                    if rst {
                        await MainActor.run {
                            self.selectedSDModel = model
                        }
                        await reBindOptions()
                    }else {
                        // Handle error case
                    }
                }
            }
        }
    }


    func setServer(url: String) {
        self.connectedUrl = url
        saveLastUrl()
    }
    
    internal func saveLastUrl() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.connectedUrl) {
            UserDefaults.standard.set(encoded, forKey: "lastUrl")
        }
    }
    
    private func loadLastUrl() {
        if let savedLastUrl = UserDefaults.standard.object(forKey: "lastUrl") as? Data {
            let decoder = JSONDecoder()
            if let loadedLastUrl = try? decoder.decode(String.self, from: savedLastUrl) {
                if !loadedLastUrl.contains("http") && !loadedLastUrl.contains("https") {
                    self.connectedUrl = "http://" + loadedLastUrl
                }else {
                    self.connectedUrl = loadedLastUrl
                }
            }
        }
    }

    public func migratePromptStyles() {
        // Migrate promptStyles to localPromptStyles
        // If a promptStyle with the same name already exists in localPromptStyles, do not add it
        for promptStyle in promptStyles {
            if !localPromptStyles.contains(where: { $0.name == promptStyle.name }) {
                localPromptStyles.append(LocalPromptStyle(name: promptStyle.name, prompt: promptStyle.prompt, negative_prompt: promptStyle.negative_prompt))
            }
        }
        saveLocalPromptStyles()
    }

    public func addPromptStyle(name: String, prompt: String, negativePrompt: String) {
        localPromptStyles.append(LocalPromptStyle(name: name, prompt: prompt, negative_prompt: negativePrompt))
        saveLocalPromptStyles()
    }

    public func updatePromptStyle(id: UUID, name: String, prompt: String, negativePrompt: String) {
        let realm = try! Realm()
        try! realm.write {
            if let promptStyle = realm.object(ofType: LocalPromptStyle.self, forPrimaryKey: id) {
                promptStyle.name = name
                promptStyle.prompt = prompt
                promptStyle.negative_prompt = negativePrompt
            }
        }
        saveLocalPromptStyles()
    }

    public func deletePromptStyle(_ name: String) {
        localPromptStyles.removeAll { $0.name == name }
        if txtSelectedPromptStyles.contains(name) {
            txtSelectedPromptStyles.removeAll { $0 == name }
        }
        if imgSelectedPromptStyles.contains(name) {
            imgSelectedPromptStyles.removeAll { $0 == name }
        }
        saveLocalPromptStyles()
    }    

    public func deletePromptStyle(index: Int) {
        localPromptStyles.remove(at: index)
        if txtSelectedPromptStyles.contains(localPromptStyles[index].name ?? "") {
            txtSelectedPromptStyles.removeAll { $0 == localPromptStyles[index].name }
        }
        if imgSelectedPromptStyles.contains(localPromptStyles[index].name ?? "") {
            imgSelectedPromptStyles.removeAll { $0 == localPromptStyles[index].name }
        }
        saveLocalPromptStyles()
    }    

    public func saveTxtSampler() {
        let realm = try! Realm()
        try! realm.write {
            // Check if there is an existing setting and update it or create a new one
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtSelectedSampler = self.txtSelectedSampler
            } else {
                let newSetting = StableSettings()
                newSetting.txtSelectedSampler = self.txtSelectedSampler
                realm.add(newSetting)
            }
        }
    }

    private func loadTxtSampler() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtSelectedSampler = setting.txtSelectedSampler
        } else {
            self.txtSelectedSampler = "Euler a" // Default value
        }
    }
    
    public func saveImgSampler() {
        let realm = try! Realm()
        try! realm.write {
            // Check if there is an existing setting and update it or create a new one
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgSelectedSampler = self.imgSelectedSampler
            } else {
                let newSetting = StableSettings()
                newSetting.imgSelectedSampler = self.imgSelectedSampler
                realm.add(newSetting)
            }
        }
    }

    private func loadImgSampler() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgSelectedSampler = setting.imgSelectedSampler
        } else {
            self.imgSelectedSampler = "Euler a" // Default value
        }
    }

    // steps
    func saveTxtSteps() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtSteps = self.txtSteps
            } else {
                let newSetting = StableSettings()
                newSetting.txtSteps = self.txtSteps
                realm.add(newSetting)
            }
        }
    }

    func loadTxtSteps() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtSteps = setting.txtSteps
        } else {
            self.txtSteps = 25 // Default value
        }
    }
    
    func saveImgSteps() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgSteps = self.imgSteps
            } else {
                let newSetting = StableSettings()
                newSetting.imgSteps = self.imgSteps
                realm.add(newSetting)
            }
        }
    }

    func loadImgSteps() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgSteps = setting.imgSteps
        } else {
            self.imgSteps = 25 // Default value
        }
    }

    func saveTxtCfgScale() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtCfgScale = self.txtCfgScale
            } else {
                let newSetting = StableSettings()
                newSetting.txtCfgScale = self.txtCfgScale
                realm.add(newSetting)
            }
        }
    }

    func loadTxtCfgScale() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtCfgScale = setting.txtCfgScale
        } else {
            self.txtCfgScale = 3.5 // Default value
        }
    }

    func saveImgCfgScale() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgCfgScale = self.imgCfgScale
            } else {
                let newSetting = StableSettings()
                newSetting.imgCfgScale = self.imgCfgScale
                realm.add(newSetting)
            }
        }
    }

    func loadImgCfgScale() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgCfgScale = setting.imgCfgScale
        } else {
            self.imgCfgScale = 3.5 // Default value
        }
    }

    // resizeMode
    public func saveResizeMode() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.resizeMode = self.resizeMode
            } else {
                let newSetting = StableSettings()
                newSetting.resizeMode = self.resizeMode
                realm.add(newSetting)
            }
        }
    }

    private func loadResizeMode() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.resizeMode = setting.resizeMode
        } else {
            self.resizeMode = 0
        }
    }

    // denoisingStrength
    public func saveDenoisingStrength() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.denoisingStrength = self.denoisingStrength
            } else {
                let newSetting = StableSettings()
                newSetting.denoisingStrength = self.denoisingStrength
                realm.add(newSetting)
            }
        }
    }

    private func loadDenoisingStrength() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.denoisingStrength = setting.denoisingStrength
        } else {
            self.denoisingStrength = 0.95
        }
    }

    // seed
    public func saveTxtSeed() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtSeed = self.txtSeed
            } else {
                let newSetting = StableSettings()
                newSetting.txtSeed = self.txtSeed
                realm.add(newSetting)
            }
        }
    }

    private func loadTxtSeed() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtSeed = setting.txtSeed
        } else {
            self.txtSeed = -1
        }
    }

    // seed
    public func saveImgSeed() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgSeed = self.imgSeed
            } else {
                let newSetting = StableSettings()
                newSetting.imgSeed = self.imgSeed
                realm.add(newSetting)
            }
        }
    }

    private func loadImgSeed() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgSeed = setting.imgSeed
        } else {
            self.imgSeed = -1
        }
    }

    public func saveTxtSelectedPromptStyles() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtSelectedPromptStyles.removeAll()
                setting.txtSelectedPromptStyles.append(objectsIn: self.txtSelectedPromptStyles)
            } else {
                let newSetting = StableSettings()
                newSetting.txtSelectedPromptStyles.append(objectsIn: self.txtSelectedPromptStyles)
                realm.add(newSetting)
            }
        }
    }

    private func loadTxtSelectedPromptStyles() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtSelectedPromptStyles = Array(setting.txtSelectedPromptStyles)
        }
    }

    public func saveImgSelectedPromptStyles() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgSelectedPromptStyles.removeAll()
                setting.imgSelectedPromptStyles.append(objectsIn: self.imgSelectedPromptStyles)
            } else {
                let newSetting = StableSettings()
                newSetting.imgSelectedPromptStyles.append(objectsIn: self.imgSelectedPromptStyles)
                realm.add(newSetting)
            }
        }
    }

    private func loadImgSelectedPromptStyles() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgSelectedPromptStyles = Array(setting.imgSelectedPromptStyles)
        }
    }

    // maskBlur
    public func saveMaskBlur() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.maskBlur = self.maskBlur
            } else {
                let newSetting = StableSettings()
                newSetting.maskBlur = self.maskBlur
                realm.add(newSetting)
            }
        }
    }

    private func loadMaskBlur() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.maskBlur = setting.maskBlur
        } else {
            self.maskBlur = 4
        }
    }

    // inpaintingFill
    public func saveInpaintingFill() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.inpaintingFill = self.inpaintingFill
            } else {
                let newSetting = StableSettings()
                newSetting.inpaintingFill = self.inpaintingFill
                realm.add(newSetting)
            }
        }
    }

    private func loadInpaintingFill() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.inpaintingFill = setting.inpaintingFill
        } else {
            self.inpaintingFill = 1
        }
    }

    public func saveMaskInvert() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.maskInvert = self.maskInvert
            } else {
                let newSetting = StableSettings()
                newSetting.maskInvert = self.maskInvert
                realm.add(newSetting)
            }
        }
    }

    private func loadMaskInvert() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.maskInvert = setting.maskInvert
        } else {
            self.maskInvert = 0
        }
    }

    public func saveInpaintFullRes() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.inpaintFullRes = self.inpaintFullRes
            } else {
                let newSetting = StableSettings()
                newSetting.inpaintFullRes = self.inpaintFullRes
                realm.add(newSetting)
            }
        }
    }

    private func loadInpaintFullRes() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.inpaintFullRes = setting.inpaintFullRes
        } else {
            self.inpaintFullRes = 0
        }
    }

    public func saveInpaintFullResPadding() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.inpaintFullResPadding = self.inpaintFullResPadding
            } else {
                let newSetting = StableSettings()
                newSetting.inpaintFullResPadding = self.inpaintFullResPadding
                realm.add(newSetting)
            }
        }
    }

    private func loadInpaintFullResPadding() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.inpaintFullResPadding = setting.inpaintFullResPadding
        } else {
            self.inpaintFullResPadding = 32
        }
    }

    public func saveClipSkip() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.clipSkip = self.clipSkip
            } else {
                let newSetting = StableSettings()
                newSetting.clipSkip = self.clipSkip
                realm.add(newSetting)
            }
        }
    }

    private func loadClipSkip() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.clipSkip = setting.clipSkip
        } else {
            self.clipSkip = 1
        }
    }

    public func saveSdVae() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.selectedSdVae = self.selectedSdVae
            } else {
                let newSetting = StableSettings()
                newSetting.selectedSdVae = self.selectedSdVae
                realm.add(newSetting)
            }
        }
    }

    private func loadSdVae() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.selectedSdVae = setting.selectedSdVae
        } else {
            self.selectedSdVae = "Automatic"
        }
    }

    public func saveTxtRestoreFaces() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txtRestoreFaces = self.txtRestoreFaces
            } else {
                let newSetting = StableSettings()
                newSetting.txtRestoreFaces = self.txtRestoreFaces
                realm.add(newSetting)
            }
        }
    }

    private func loadTxtRestoreFaces() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.txtRestoreFaces = setting.txtRestoreFaces
        } else {
            self.txtRestoreFaces = false
        }
    }

    public func saveImgRestoreFaces() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.imgRestoreFaces = self.imgRestoreFaces
            } else {
                let newSetting = StableSettings()
                newSetting.imgRestoreFaces = self.imgRestoreFaces
                realm.add(newSetting)
            }
        }
    }

    private func loadImgRestoreFaces() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.imgRestoreFaces = setting.imgRestoreFaces
        } else {
            self.imgRestoreFaces = false
        }
    }

    public func saveLocalPromptStyles() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.localPromptStyles.removeAll()
                setting.localPromptStyles.append(objectsIn: self.localPromptStyles)
            } else {
                let newSetting = StableSettings()
                newSetting.localPromptStyles.append(objectsIn: self.localPromptStyles)
                realm.add(newSetting)
            }
        }
    }

    private func loadLocalPromptStyles() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.localPromptStyles = Array(setting.localPromptStyles)
        }
    }

    public func saveIsInpaintMode() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.isInpaintMode = self.isInpaintMode
            } else {
                let newSetting = StableSettings()
                newSetting.isInpaintMode = self.isInpaintMode
                realm.add(newSetting)
            }
        }
    }

    private func loadIsInpaintMode() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.isInpaintMode = setting.isInpaintMode
        } else {
            self.isInpaintMode = false
        }
    }
    
    func saveSoftInpaintingSettings() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.softInpainting = self.softInpainting
                setting.scheduleBias = self.scheduleBias
                setting.preservationStrength = self.preservationStrength
                setting.transitionContrastBoost = self.transitionContrastBoost
            } else {
                let newSetting = StableSettings()
                newSetting.softInpainting = self.softInpainting
                newSetting.scheduleBias = self.scheduleBias
                newSetting.preservationStrength = self.preservationStrength
                newSetting.transitionContrastBoost = self.transitionContrastBoost
                realm.add(newSetting)
            }
        }
    }

    func loadSoftInpaintingSettings() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            if setting.transitionContrastBoost == 0 {
                self.softInpainting = false
                self.scheduleBias = 1
                self.preservationStrength = 0.5
                self.transitionContrastBoost = 4
            }else {
                self.softInpainting = setting.softInpainting
                self.scheduleBias = setting.scheduleBias
                self.preservationStrength = setting.preservationStrength
                self.transitionContrastBoost = setting.transitionContrastBoost
            }
        }
    }
}
