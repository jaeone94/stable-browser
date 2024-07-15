import RealmSwift
class StableSettings: Object {
    @Persisted var selectedSampler: String = "Euler a"
    @Persisted var steps: Int = 20
    @Persisted var cfgScale: Double = 7.5
    @Persisted var resizeMode: Int = 0
    @Persisted var denoisingStrength: Double = 0.5
    @Persisted var seed: Int = -1
    @Persisted var restoreFaces: Bool = false
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
    @Persisted var clipSkip: Int = 1
    @Persisted var selectedSdVae: String = "Automatic"
    @Persisted var selectedPromptStyles: List<String> = List<String>()
    @Persisted var localPromptStyles: List<LocalPromptStyle> = List<LocalPromptStyle>()

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
}
