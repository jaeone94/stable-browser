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
    @Published var loras: [String] = []
    @Published var embeddings: [String] = []

    // Image generate properties
    @Published var selectedSDModel: String = ""
    @Published var clipSkip: Int = 1
    @Published var selectedSdVae: String = "Automatic"
    @Published var selectedPromptStyles: [String] = []
    @Published var selectedSampler: String = ""
    @Published var steps: Int = 20
    @Published var cfgScale: Double = 7.5
    @Published var resizeMode: Int = 0
    @Published var denoisingStrength: Double = 0.5
    @Published var seed: Int = -1
    @Published var restoreFaces: Bool = false

    // Inpaint properties
    @Published var isInpaintMode: Bool = false
    @Published var maskBlur: Int = 2
    @Published var inpaintingFill: Int = 1 // 0: original, 1: fill
    @Published var maskInvert: Int = 0 // 0: inpaint masked, 1: inpaint not masked
    @Published var inpaintFullRes: Int = 0 // 0: whole picture, 1: only masked
    @Published var inpaintFullResPadding: Int = 32 // only masked padding pixels    

    // maximum image size (width or height, whichever is larger)
    @Published var maxImageSize: Int = -1
    var maxImageSizeEnabled: Bool {
        get {
            return maxImageSize > 0
        }
    }
    
    // Txt2Img specific properties
    @Published var txt2imgPrompt: String = ""
    @Published var txt2imgNegativePrompt: String = ""
    @Published var txt2imgBatchCount: Int = 1
    @Published var txt2imgWidth: Int = 512
    @Published var txt2imgHeight: Int = 512
    @Published var txt2imgDenoisingStrength: Double = 0.7
    @Published var txt2imgEnableHR: Bool = false
    @Published var txt2imgHrScale: Double = 2.0
    @Published var txt2imgHrUpscaler: HiResUpscaler = .latent
    @Published var txt2imgHrSecondPassSteps: Int = 0
    @Published var txt2imgHrResizeX: Int = 0
    @Published var txt2imgHrResizeY: Int = 0

    var ip: String?
    var port: String?

    var fullUrl : String {
        get {
            if let ipAddress = ip, let port = port {
                return ipAddress + ":" + port
            }
            return ""
        }
    }

    
    public func tryAutoConnectToServer() {
        if let ipAddress = ip, let port = port {
            let (cleanAddress, useHttps, cleanPort) = StringUtils.processAddress(ipAddress, port: port)
            let api = WebUIApi(host: cleanAddress, port: cleanPort, useHttps: useHttps)
            
            Task {
                await connectToServer(api: api)
            }
        } else {
            DispatchQueue.main.async {
                self.isConnected = false
            }
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
            
        } else {
            await MainActor.run {
                self.isConnected = false
            }
        }
    }

    public func saveCurrentSettings() {
        if isConnected ?? false {
            saveSampler()
            saveSteps()
            saveCfgScale()
            saveDenoisingStrength()
            saveResizeMode()
            saveSeed()
            saveSelectedPromptStyles()
            saveMaskBlur()
            saveInpaintingFill()
            saveMaskInvert()
            saveInpaintFullRes()
            saveInpaintFullResPadding()
            saveClipSkip()
            saveSdVae()
            saveRestoreFaces()
            saveLocalPromptStyles()
            saveIsInpaintMode()
            saveTxt2ImgSettings()
        }
    }

    public func loadCurrentSettings() {
        loadLastUrl()
        loadSampler()
        loadSteps()
        loadCfgScale()
        loadDenoisingStrength()
        loadResizeMode()
        loadSeed()
        loadSelectedPromptStyles()
        loadMaskBlur()
        loadInpaintingFill()
        loadMaskInvert()
        loadInpaintFullRes()
        loadInpaintFullResPadding()
        loadClipSkip()
        loadSdVae()
        loadRestoreFaces()
        loadLocalPromptStyles()
        loadIsInpaintMode()
        loadTxt2ImgSettings()
    }
    
    private func saveTxt2ImgSettings() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.txt2imgPrompt = txt2imgPrompt
                setting.txt2imgNegativePrompt = txt2imgNegativePrompt
                setting.txt2imgBatchCount = txt2imgBatchCount
                setting.txt2imgWidth = txt2imgWidth
                setting.txt2imgHeight = txt2imgHeight
                setting.txt2imgDenoisingStrength = txt2imgDenoisingStrength
                setting.txt2imgEnableHR = txt2imgEnableHR
                setting.txt2imgHrScale = txt2imgHrScale
                setting.txt2imgHrUpscaler = txt2imgHrUpscaler.rawValue
                setting.txt2imgHrSecondPassSteps = txt2imgHrSecondPassSteps
                setting.txt2imgHrResizeX = txt2imgHrResizeX
                setting.txt2imgHrResizeY = txt2imgHrResizeY
            } else {
                let newSetting = StableSettings()
                newSetting.txt2imgPrompt = txt2imgPrompt
                newSetting.txt2imgNegativePrompt = txt2imgNegativePrompt
                newSetting.txt2imgBatchCount = txt2imgBatchCount
                newSetting.txt2imgWidth = txt2imgWidth
                newSetting.txt2imgHeight = txt2imgHeight
                newSetting.txt2imgDenoisingStrength = txt2imgDenoisingStrength
                newSetting.txt2imgEnableHR = txt2imgEnableHR
                newSetting.txt2imgHrScale = txt2imgHrScale
                newSetting.txt2imgHrUpscaler = txt2imgHrUpscaler.rawValue
                newSetting.txt2imgHrSecondPassSteps = txt2imgHrSecondPassSteps
                newSetting.txt2imgHrResizeX = txt2imgHrResizeX
                newSetting.txt2imgHrResizeY = txt2imgHrResizeY
                realm.add(newSetting)
            }
        }
    }

    private func loadTxt2ImgSettings() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            txt2imgPrompt = setting.txt2imgPrompt
            txt2imgNegativePrompt = setting.txt2imgNegativePrompt
            txt2imgBatchCount = setting.txt2imgBatchCount
            txt2imgWidth = setting.txt2imgWidth
            txt2imgHeight = setting.txt2imgHeight
            txt2imgDenoisingStrength = setting.txt2imgDenoisingStrength
            txt2imgEnableHR = setting.txt2imgEnableHR
            txt2imgHrScale = setting.txt2imgHrScale
            txt2imgHrUpscaler = HiResUpscaler(rawValue: setting.txt2imgHrUpscaler) ?? .latent
            txt2imgHrSecondPassSteps = setting.txt2imgHrSecondPassSteps
            txt2imgHrResizeX = setting.txt2imgHrResizeX
            txt2imgHrResizeY = setting.txt2imgHrResizeY
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
    
    func setSampler(sampler: String) {
        self.selectedSampler = sampler
        saveSampler()
    }


    func setServer(ip: String, port: String) {
        self.ip = ip
        self.port = port
        saveLastUrl()
    }
    
    internal func saveLastUrl() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(fullUrl) {
            UserDefaults.standard.set(encoded, forKey: "lastUrl")
        }
    }
    
    private func loadLastUrl() {
        if let savedLastUrl = UserDefaults.standard.object(forKey: "lastUrl") as? Data {
            let decoder = JSONDecoder()
            if let loadedLastUrl = try? decoder.decode(String.self, from: savedLastUrl) {
                let url = loadedLastUrl.split(separator: ":")
                if loadedLastUrl.contains("http") {
                    self.ip = String(url[0] + ":" + url[1])
                    self.port = String(url[2])
                }else {
                    self.ip = String(url[0])
                    self.port = String(url[1])
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
        if selectedPromptStyles.contains(name) {
            selectedPromptStyles.removeAll { $0 == name }
        }
        saveLocalPromptStyles()
    }    

    public func deletePromptStyle(index: Int) {
        localPromptStyles.remove(at: index)
        if selectedPromptStyles.contains(localPromptStyles[index].name ?? "") {
            selectedPromptStyles.removeAll { $0 == localPromptStyles[index].name }
        }
        saveLocalPromptStyles()
    }    

    public func saveSampler() {
        let realm = try! Realm()
        try! realm.write {
            // Check if there is an existing setting and update it or create a new one
            if let setting = realm.objects(StableSettings.self).first {
                setting.selectedSampler = self.selectedSampler
            } else {
                let newSetting = StableSettings()
                newSetting.selectedSampler = self.selectedSampler
                realm.add(newSetting)
            }
        }
    }

    private func loadSampler() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.selectedSampler = setting.selectedSampler
        } else {
            self.selectedSampler = "Euler a" // Default value
        }
    }

    // steps
    func saveSteps() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.steps = self.steps
            } else {
                let newSetting = StableSettings()
                newSetting.steps = self.steps
                realm.add(newSetting)
            }
        }
    }

    func loadSteps() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.steps = setting.steps
        } else {
            self.steps = 25 // Default value
        }
    }

    func saveCfgScale() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.cfgScale = self.cfgScale
            } else {
                let newSetting = StableSettings()
                newSetting.cfgScale = self.cfgScale
                realm.add(newSetting)
            }
        }
    }

    func loadCfgScale() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.cfgScale = setting.cfgScale
        } else {
            self.cfgScale = 3.5 // Default value
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
    public func saveSeed() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.seed = self.seed
            } else {
                let newSetting = StableSettings()
                newSetting.seed = self.seed
                realm.add(newSetting)
            }
        }
    }

    private func loadSeed() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.seed = setting.seed
        } else {
            self.seed = -1
        }
    }

    public func saveSelectedPromptStyles() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.selectedPromptStyles.removeAll()
                setting.selectedPromptStyles.append(objectsIn: self.selectedPromptStyles)
            } else {
                let newSetting = StableSettings()
                newSetting.selectedPromptStyles.append(objectsIn: self.selectedPromptStyles)
                realm.add(newSetting)
            }
        }
    }

    private func loadSelectedPromptStyles() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.selectedPromptStyles = Array(setting.selectedPromptStyles)
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

    public func saveRestoreFaces() {
        let realm = try! Realm()
        try! realm.write {
            if let setting = realm.objects(StableSettings.self).first {
                setting.restoreFaces = self.restoreFaces
            } else {
                let newSetting = StableSettings()
                newSetting.restoreFaces = self.restoreFaces
                realm.add(newSetting)
            }
        }
    }

    private func loadRestoreFaces() {
        let realm = try! Realm()
        if let setting = realm.objects(StableSettings.self).first {
            self.restoreFaces = setting.restoreFaces
        } else {
            self.restoreFaces = false
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
}
