import UIKit

class StableGenerationContext: ObservableObject, Equatable, Identifiable {
    let id = UUID()
    @Published var type: GenerationContext = .img2img
    @Published var state: GenerationState = .idle
    
    // for Equatable
    static func == (lhs: StableGenerationContext, rhs: StableGenerationContext) -> Bool {
            return lhs.id == rhs.id
        }
    
    @Published var progress: Float = 0.0
    @Published var isSkipped: Bool = false
    @Published var isInterrupted: Bool = false
    @Published var payload: [String: Any] = [:]
    
    var resultMap: WebUIApiResult? {
            get {
                CacheManager.shared.loadResultMap(for: id)
            }
            set {
                if let newValue = newValue {
                    CacheManager.shared.saveResultMap(newValue, for: id)
                }
            }
        }
    @Published var resultImages: [ResultImage]?
    @Published var errorDesc: String?
        
    enum GenerationContext: CustomStringConvertible {
        case txt2img, img2img
        
        var description: String {
            switch self {
            case .txt2img: return "Text to Image"
            case .img2img: return "Image to Image"
            }
        }
    }

    enum GenerationState: CustomStringConvertible {
        case idle, ready, inProgress, stopping, canceled, completed, stopped, error
        
        var description: String {
            switch self {
            case .idle: return "Idle"
            case .ready: return "Ready"
            case .inProgress: return "In Progress"
            case .stopping: return "Stopping"
            case .canceled: return "Canceled"
            case .completed: return "Completed"
            case .stopped: return "Stopped"
            case .error: return "Error"
            }
        }
    }
    
    public func generate() {
        updateProgress()
        Task {
            let context = self.type == .img2img ? "img2img" : "txt2img"
            
            if let resultMap = await WebUIApi.shared.genImg(context: context, payload: payload) {
                await MainActor.run {
                    self.progress = 1
                    if resultMap.images.count > 0 {
                        self.state = self.state == .stopping ? .stopped : .completed
                        self.resultMap = resultMap
                    } else {
                        self.state = .error
                    }
                }
            }else {
                await MainActor.run {
                    self.state = .error
                }
            }
        }
    }
    
    public func stop() {
        state = .stopping
        skip()
        interrupt()
    }
    
    private func skip() {
        Task {
            await WebUIApi.shared.skip()
        }
    }
    
    private func interrupt() {
        Task {
            await WebUIApi.shared.interrupt()
        }
    }
    
    private func updateProgress() {
        Task {
            while self.state == .ready || self.state == .inProgress {
                if let progress = await WebUIApi.shared.getProgress() {
                    print(id, "  ", progress.progress)
                    if progress.progress > 0 {
                        await MainActor.run {
                            if self.state == .ready {
                                self.state = .inProgress
                            }
                            self.progress = Float(progress.progress)
                        }
                    }
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }
    
    internal func getResultImages() -> [ResultImage] {
        if let resultMap = self.resultMap {
            return parseResultMap(resultMap)
        }else {
            return []
        }
    }
    
    internal func getInitImage() -> UIImage? {
        if let b64Images = payload["init_images"] as? [String], let b64Image = b64Images.first {
            if let uiImage = ImageUtils.base64ToImage(b64Image) {
                return uiImage
            }
        }
        return nil
    }
    
    private func parseResultMap(_ result: WebUIApiResult) -> [ResultImage] {
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
                ] as [String : Any]
                let b64Image = result.images[index]
                if let uiImage = ImageUtils.base64ToImage(b64Image) {
                    let seed = newInfo["seed"] as! Int
                    let subSeed = newInfo["subseed"] as! Int
                    let resultImage = ResultImage(image: uiImage, info: newInfo, seed: seed, subSeed: subSeed)
                    resultImages.append(resultImage)
                }
            }
        }
        return resultImages
    }
}

