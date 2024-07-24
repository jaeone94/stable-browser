import RealmSwift

class StableSettings: Object {
    // Common settings
    @Persisted var clipSkip: Int = 1
    @Persisted var selectedSdVae: String = "Automatic"
    @Persisted var localPromptStyles: List<LocalPromptStyle> = List<LocalPromptStyle>()

    // Txt2Img specific settings
    @Persisted var txtSelectedSampler: String = "Euler a"
    @Persisted var txtSteps: Int = 20
    @Persisted var txtCfgScale: Double = 7.5
    @Persisted var txtSeed: Int = -1
    @Persisted var txtRestoreFaces: Bool = false
    @Persisted var txtSelectedPromptStyles: List<String> = List<String>()
    @Persisted var txt2imgPrompt: String = ""
    @Persisted var txt2imgNegativePrompt: String = ""
    @Persisted var txt2imgBatchCount: Int = 1
    @Persisted var txt2imgWidth: Int = 512
    @Persisted var txt2imgHeight: Int = 512
    @Persisted var txt2imgDenoisingStrength: Double = 0.7
    @Persisted var txt2imgEnableHR: Bool = false
    @Persisted var txt2imgHrScale: Double = 2.0
    @Persisted var txt2imgHrUpscaler: String = "Latent"
    @Persisted var txt2imgHrSecondPassSteps: Int = 0
    @Persisted var txt2imgHrResizeX: Int = 0
    @Persisted var txt2imgHrResizeY: Int = 0
    @Persisted var txtSelectedScheduler: String = "automatic"

    // Img2Img specific settings
    @Persisted var imgSelectedSampler: String = "Euler a"
    @Persisted var imgSteps: Int = 20
    @Persisted var imgCfgScale: Double = 7.5
    @Persisted var imgSeed: Int = -1
    @Persisted var imgRestoreFaces: Bool = false
    @Persisted var imgSelectedPromptStyles: List<String> = List<String>()
    @Persisted var imgPrompt: String = ""
    @Persisted var imgNegativePrompt: String = ""
    @Persisted var resizeMode: Int = 0
    @Persisted var denoisingStrength: Double = 0.5
    @Persisted var isInpaintMode: Bool = false
    @Persisted var maskBlur: Int = 2
    @Persisted var inpaintingFill: Int = 1
    @Persisted var maskInvert: Int = 0
    @Persisted var inpaintFullRes: Int = 0
    @Persisted var inpaintFullResPadding: Int = 32
    @Persisted var softInpainting: Bool = false
    @Persisted var scheduleBias: Double = 1.0
    @Persisted var preservationStrength: Double = 0.5
    @Persisted var transitionContrastBoost: Double = 4.0
    @Persisted var imgSelectedScheduler: String = "automatic"
}
