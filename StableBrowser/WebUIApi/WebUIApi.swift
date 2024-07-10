import UIKit

struct Interrupt: Decodable {
    let interrupted: Bool
}

struct Skip: Decodable {
    let skipped: Bool
}

struct Progress: Decodable {
    let progress: Double
    let state: ProgressState
}

struct ProgressState: Decodable {    
    let skipped: Bool
    let interrupted: Bool
    let job: String
    let job_count: Int
    let job_timestamp: String
    let job_no: Int
    let sampling_step: Int
    let sampling_steps: Int
}

enum Img2ImgMode {
    case normal
    case inpaint
}


class WebUIApi {
    private let baseURL: URL
    private let defaultSampler: String
    private let defaultSteps: Int
    
    private let session: URLSession
    
    init(host: String = "127.0.0.1", port: Int = 7860, useHttps: Bool = false, sampler: String = "Euler a", steps: Int = 20) {
        let scheme = useHttps ? "https" : "http"
        if useHttps {
            self.baseURL = URL(string: "\(scheme)://\(host)/sdapi/v1")!
        }else {
            self.baseURL = URL(string: "\(scheme)://\(host):\(port)/sdapi/v1")!
        }
        
        self.defaultSampler = sampler
        self.defaultSteps = steps
        
        self.session = URLSession.shared
    }
    
    private func toApiResult(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> WebUIApiResult? {
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        var images: [UIImage] = []
        if let imageStrings = json["images"] as? [String] {
            images = imageStrings.compactMap { ImageUtils.base64ToImage($0) }
        } else if let imageString = json["image"] as? String {
            images = [ImageUtils.base64ToImage(imageString)].compactMap { $0 }
        }
        
        let parameters = json["parameters"] as? [String: Any] ?? [:]
        let info = json["info"] as? [String: Any] ?? [:]
        
        return WebUIApiResult(images: images, parameters: parameters, info: info, json: json)
    }

    func img2img(mode: Img2ImgMode,
                 initImages: [UIImage],
                 mask: UIImage? = nil,
                 maskBlur: Int = 30,
                 inpaintingFill: Int = 0,
                 inpaintFullRes: Bool = true,
                 inpaintFullResPadding: Int = 1,
                 inpaintingMaskInvert: Int = 1,
                 resizeMode: Int = 0,
                 denoisingStrength: Double = 0.7,
                 prompt: String,
                 negativePrompt: String = "",
                 styles: [String] = [],
                 seed: Int = -1,
                 subseed: Int = -1,
                 subseedStrength: Double = 0,
                 seedResizeFromH: Int = 0,
                 seedResizeFromW: Int = 0,
                 samplerName: String? = nil,
                 batchSize: Int = 1,
                 nIter: Int = 1,
                 steps: Int? = nil,
                 cfgScale: Double = 7,
                 width: Int = 512,
                 height: Int = 512,
                 restoreFaces: Bool = false,
                 tiling: Bool = false,
                 doNotSaveSamples: Bool = false,
                 doNotSaveGrid: Bool = false,
                 eta: Double = 1,
                 sChurn: Double = 0,
                 sTmax: Double = 0,
                 sTmin: Double = 0,
                 sNoise: Double = 1,
                 overrideSettings: [String: Any] = [:],
                 overrideSettingsRestoreAfterwards: Bool = true,
                 includeInitImages: Bool = true,
                 scriptArgs: [Any] = [],
                 sendImages: Bool = true,
                 saveImages: Bool = false,
                 alwaysonScripts: [String: [String: Any]] = [:]) async -> WebUIApiResult? {
        
        let initImagesBase64 = initImages.map { ImageUtils.rawB64img($0) }
        let maskBase64 = mask.map { ImageUtils.rawB64img($0) }
        
        var payload: [String: Any] = [
            "init_images": initImagesBase64,
            "denoising_strength": denoisingStrength,
            "prompt": prompt,
            "negative_prompt": negativePrompt,
            "styles": styles,
            "seed": seed,
            "subseed": subseed,
            "subseed_strength": subseedStrength,
            "seed_resize_from_h": seedResizeFromH,
            "seed_resize_from_w": seedResizeFromW,
            "sampler_name": samplerName ?? defaultSampler,
            "batch_size": batchSize,
            "n_iter": nIter,
            "steps": steps ?? defaultSteps,
            "cfg_scale": cfgScale,
            "width": width,
            "height": height,
            "restore_faces": restoreFaces,
            "tiling": tiling,
            "do_not_save_samples": doNotSaveSamples,
            "do_not_save_grid": doNotSaveGrid,
            "eta": eta,
            "s_churn": sChurn,
            "s_tmax": sTmax,
            "s_tmin": sTmin,
            "s_noise": sNoise,
            "override_settings": overrideSettings,
            "override_settings_restore_afterwards": overrideSettingsRestoreAfterwards,
            "include_init_images": includeInitImages,
            "script_args": scriptArgs,
            "send_images": sendImages,
            "save_images": saveImages,
            "alwayson_scripts": alwaysonScripts
        ]
        
        if mode == .inpaint {
            payload["mask"] = maskBase64 ?? "";
            payload["mask_blur"] = maskBlur;
            payload["inpainting_fill"] = inpaintingFill;
            payload["inpaint_full_res"] = inpaintFullRes;
            payload["inpaint_full_res_padding"] = inpaintFullResPadding;
            payload["inpainting_mask_invert"] = inpaintingMaskInvert;
            payload["resize_mode"] = resizeMode;            
        }
        
        return await sendRequest(path: "img2img", payload: payload)
    }
    
    func txt2img(
        enable_hr: Bool = false,
        denoising_strength: Double = 0.7,
        firstphase_width: Int = 0,
        firstphase_height: Int = 0,
        hr_scale: Double = 2.0,
        hr_upscaler: HiResUpscaler = .latent,
        hr_second_pass_steps: Int = 0,
        hr_resize_x: Int = 0,
        hr_resize_y: Int = 0,
        prompt: String = "",
        styles: [String] = [],
        seed: Int = -1,
        subseed: Int = -1,
        subseed_strength: Double = 0.0,
        seed_resize_from_h: Int = 0,
        seed_resize_from_w: Int = 0,
        sampler_name: String? = nil,
        batch_size: Int = 1,
        n_iter: Int = 1,
        steps: Int? = nil,
        cfg_scale: Double = 7.0,
        width: Int = 512,
        height: Int = 512,
        restore_faces: Bool = false,
        tiling: Bool = false,
        do_not_save_samples: Bool = false,
        do_not_save_grid: Bool = false,
        negative_prompt: String = "",
        eta: Double = 1.0,
        s_churn: Double = 0.0,
        s_tmax: Double = 0.0,
        s_tmin: Double = 0.0,
        s_noise: Double = 1.0,
        override_settings: [String: Any] = [:],
        override_settings_restore_afterwards: Bool = true,
        script_args: [Any]? = nil,
        script_name: String? = nil,
        send_images: Bool = true,
        save_images: Bool = false,
        alwayson_scripts: [String: Any] = [:],
        // controlnet_units: [ControlNetUnit] = [],
        // adetailer: [ADetailer] = [],
        // roop: Roop? = nil,
        // reactor: ReActor? = nil,
        // sag: Sag? = nil,
        sampler_index: String? = nil,
        use_deprecated_controlnet: Bool = false,
        use_async: Bool = false
    ) async -> WebUIApiResult? {
        let samplerName = sampler_name ?? defaultSampler
        let stepsCount = steps ?? defaultSteps
        let scriptArgs = script_args ?? []
        
        let payload: [String: Any] = [
            "enable_hr": enable_hr,
            "hr_scale": hr_scale,
            "hr_upscaler": hr_upscaler.rawValue,
            "hr_second_pass_steps": hr_second_pass_steps,
            "hr_resize_x": hr_resize_x,
            "hr_resize_y": hr_resize_y,
            "denoising_strength": denoising_strength,
            "firstphase_width": firstphase_width,
            "firstphase_height": firstphase_height,
            "prompt": prompt,
            "styles": styles,
            "seed": seed,
            "subseed": subseed,
            "subseed_strength": subseed_strength,
            "seed_resize_from_h": seed_resize_from_h,
            "seed_resize_from_w": seed_resize_from_w,
            "batch_size": batch_size,
            "n_iter": n_iter,
            "steps": stepsCount,
            "cfg_scale": cfg_scale,
            "width": width,
            "height": height,
            "restore_faces": restore_faces,
            "tiling": tiling,
            "do_not_save_samples": do_not_save_samples,
            "do_not_save_grid": do_not_save_grid,
            "negative_prompt": negative_prompt,
            "eta": eta,
            "s_churn": s_churn,
            "s_tmax": s_tmax,
            "s_tmin": s_tmin,
            "s_noise": s_noise,
            "override_settings": override_settings,
            "override_settings_restore_afterwards": override_settings_restore_afterwards,
            "sampler_name": samplerName,
            "sampler_index": sampler_index ?? samplerName,
            "script_name": script_name ?? "",
            "script_args": scriptArgs,
            "send_images": send_images,
            "save_images": save_images,
            "alwayson_scripts": alwayson_scripts,
        ]

        // TODO: Implement these features
        // if use_deprecated_controlnet, !controlnet_units.isEmpty {
        //     payload["controlnet_units"] = controlnet_units.map { $0.toDictionary() }
        //     return await sendRequest(path: "controlnet/txt2img", payload: payload)
        // }
 
        // if !adetailer.isEmpty {
        //     var ads = [true]
        //     ads.append(contentsOf: adetailer.map { $0.toDictionary() })
        //     payload["alwayson_scripts"]["ADetailer"] = ["args": ads]
        // } else if hasADetailer {
        //     payload["alwayson_scripts"]["ADetailer"] = ["args": [false]]
        // }
        // 
        // if let roop = roop {
        //     payload["alwayson_scripts"]["roop"] = ["args": roop.toDictionary()]
        // }
        // 
        // if let reactor = reactor {
        //     payload["alwayson_scripts"]["reactor"] = ["args": reactor.toDictionary()]
        // }
 
        // if let sag = sag {
        //     payload["alwayson_scripts"]["Self Attention Guidance"] = ["args": sag.toDictionary()]
        // }
 
        // if !controlnet_units.isEmpty {
        //     payload["alwayson_scripts"]["ControlNet"] = ["args": controlnet_units.map { $0.toDictionary() }]
        // } else if hasControlNet {
        //     payload["alwayson_scripts"]["ControlNet"] = ["args": []]
        // }
        
        return await sendRequest(path: "txt2img", payload: payload)
    }
    
    func getOptions() async -> Options? {
        return await sendGetRequest(path: "options")
    }
    
    func getOptionsWithTimeout() async -> Options? {
        return await sendGetRequest(path: "options", timeoutInterval: 2)
    }
    
    func setOptions(_ options: Options) async -> Bool {
        return await sendOptionPostRequest(path: "options", payload: options)
    }
    
    func interrupt() async -> Interrupt? {
        return await sendPostRequest(path: "interrupt")
    }
    
    func skip() async -> Skip? {
        return await sendPostRequest(path: "skip")
    }

    func getHypernetworks() async -> [String]? {
        return await sendGetRequest(path: "hypernetworks")
    }

    func getFaceRestorers() async -> [String]? {
        return await sendGetRequest(path: "face-restorers")
    }

    func getRealesrganModels() async -> [String]? {
        return await sendGetRequest(path: "realesrgan-models")
    }

    func getPromptStyles() async -> [PromptStyle]? {
        return await sendGetRequest(path: "prompt-styles")
    }

    func getOptions(key: String) async -> [String]? {
        return await sendGetRequest(path: key)
    }

    func getSamplers() async -> [String]? {
        return await sendGetRequest(path: "samplers", key: "name")
    }

    func getSDModels() async -> [SDModel]? {
        return await sendGetRequest(path: "sd-models")
    }
    
    func getProgress() async -> Progress? {
        return await sendGetRequest(path: "progress")
    }

    func getCmdFlags() async -> [String: String]? {
        return await sendGetRequest(path: "cmd-flags")
    }

    func getSdVae() async -> [String]? {
        return await sendGetRequest(path: "sd-vae", key: "model_name")
    }

    func getUpscalers() async -> [String]? {
        return await sendGetRequest(path: "upscalers")
    }

    func getLatentUpscaleModes() async -> [String]? {
        return await sendGetRequest(path: "latent-upscale-modes")
    }

    func getLoras() async -> [String]? {
        return await sendGetRequest(path: "loras", key: "name")
    }

    func getArtistCategories() async -> [String]? {
        return await sendGetRequest(path: "artist-categories")
    }

    func getArtists() async -> [String]? {
        return await sendGetRequest(path: "artists")
    }

    func refreshCheckpoints() async -> [String]? {
        return await sendPostRequest(path: "refresh-checkpoints")
    }

    func getScripts() async -> [String]? {
        return await sendGetRequest(path: "scripts")
    }

    func getEmbeddings() async -> [String]? {
        return await sendGetRequest(path: "embeddings")
    }

    func getMemory() async -> [String]? {
        return await sendGetRequest(path: "memory")
    }
    
    func utilGetModelNames() async -> [String] {
        let sdModels = await getSDModels() ?? []
        return sdModels.map { $0.title ?? "" }.sorted()
    }

    func utilSetModel(name: String, findClosest: Bool = true, options: Options) async -> Bool {
        var modelName = name
        if findClosest {
            modelName = modelName.lowercased()
        }
        let models = await utilGetModelNames()
        var foundModel: String?
        
        if models.contains(modelName) {
            foundModel = modelName
        } else if findClosest {
            var maxSimilarity = 0.0
            var maxModel = models[0]
            for model in models {
                let similarity = stringSimularity(a: modelName, b: model)
                if similarity >= maxSimilarity {
                    maxSimilarity = similarity
                    maxModel = model
                }
            }
            foundModel = maxModel
        }
        
        if let foundModel = foundModel {
            print("Loading \(foundModel)")
            if var options = await getOptions() {
                options.sd_model_checkpoint = foundModel
                if await setOptions(options) {
                    print("Model changed to \(foundModel)")
                }else {
                    print("Failed to change model to \(foundModel)")
                }
                
            }
            
            return true
        } else {
            print("Model not found")
            return false
        }
    }

    // stringSimularity : Calculate the similarity between two strings
    func stringSimularity(a: String, b: String) -> Double {
        let aCount = a.count
        let bCount = b.count
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)
        
        for i in 1...aCount {
            for j in 1...bCount {
                if a[a.index(a.startIndex, offsetBy: i - 1)] == b[b.index(b.startIndex, offsetBy: j - 1)] {
                    matrix[i][j] = matrix[i - 1][j - 1] + 1
                } else {
                    matrix[i][j] = max(matrix[i - 1][j], matrix[i][j - 1])
                }
            }
        }
        
        return Double(matrix[aCount][bCount]) / Double(max(aCount, bCount))
    }
    
    func utilGetCurrentModel() async -> String? {
        if let options = await getOptions() {
            if let checkpoint = options.sd_model_checkpoint as String? {
                return checkpoint
            } else if let sdModels = await getSDModels(), let hash = options.sd_checkpoint_hash as String? {
                let model = sdModels.first { $0.hash == hash }
                return model?.title
            }
        }
        return nil
    }

    func utilWaitForReady(checkInterval: TimeInterval = 5.0) async {
        while true {
            if let result = await getProgress() {
                let progress = result.progress as Double? ?? 0.0
                let jobCount = 1 // do something
                if progress == 0.0 && jobCount == 0 {
                    break
                } else {
                    print("[WAIT]: progress = \(String(format: "%.4f", progress)), job_count = \(jobCount)")
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                }
            }
        }
    }


    
    private func sendGetRequest<T: Decodable>(path: String, key: String = "", timeoutInterval: TimeInterval = 10.0) async -> T? {
        let url = baseURL.appendingPathComponent(path)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval // Set the timeout interval here
        let session = URLSession(configuration: configuration)
        
        do {
            let (data, rst) = try await session.data(from: url)
            let decoder = JSONDecoder()
            if key.isEmpty {
                return try decoder.decode(T.self, from: data)
            } else {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = jsonObject as? [Any] {
                    let values = array.compactMap { ($0 as? [String: Any])?[key] }
                    return try decoder.decode(T.self, from: try JSONSerialization.data(withJSONObject: values, options: []))
                }
                else {
                    return nil
                }
            }
        } catch {
            print("Error sending GET request: \(error)")
            return nil
        }
    }
        
    private func sendPostRequest<T: Decodable>(path: String, payload: [String: Any] = [:]) async -> T? {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            return nil
        }
        
        do {
            let (data, _) = try await session.data(for: request)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error sending POST request: \(error)")
            return nil
        }
    }
    
    private func sendOptionPostRequest(path: String, payload: Options) async -> Bool {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(payload)
        } catch {
            print("Error encoding payload: \(error)")
            return false
        }
        
        do {
            let (_, data2) = try await session.data(for: request)
            if let httpResponse = data2 as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    return true
                }
            }
            return false
        } catch {
            print("Error sending POST request: \(error)")
            return false
        }
    }
    
    private func sendRequest(path: String, payload: [String: Any]) async -> WebUIApiResult? {
        let url = baseURL.appendingPathComponent(path)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing payload: \(error)")
            return nil
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            return toApiResult(data, response, nil)
        } catch {
            print("Error sending request: \(error)")
            return nil
        }
    }
}
