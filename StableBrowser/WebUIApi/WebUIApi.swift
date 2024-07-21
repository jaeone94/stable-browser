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


class WebUIApi: ObservableObject {
    static let shared = WebUIApi()
    private var baseURL: URL
    internal var defaultSampler: String
    internal var defaultSteps: Int
    
    private var session: URLSession
    
    init(host: String = "127.0.0.1", useUrl: Bool = false, scheme: String = "http", port: Int = 7860, sampler: String = "Euler a", steps: Int = 20) {
        if useUrl {
            self.baseURL = URL(string: "\(scheme)://\(host)/sdapi/v1")!
        }else {
            self.baseURL = URL(string: "\(scheme)://\(host):\(port)/sdapi/v1")!
        }
        
        self.defaultSampler = sampler
        self.defaultSteps = steps
        
        self.session = URLSession.shared
    }
    
    public func setConnectionProperties(_ processedAddress: ProcessedAddress, sampler: String = "Euler a", steps: Int = 20) {
        if processedAddress.hasPort {
            self.baseURL = URL(string: "\(processedAddress.scheme)://\(processedAddress.cleanAddress):\(processedAddress.port)/sdapi/v1")!
        }else {
            self.baseURL = URL(string: "\(processedAddress.scheme)://\(processedAddress.cleanAddress)/sdapi/v1")!
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

    func genImg(context: String, payload: [String: Any]) async -> WebUIApiResult? {
        return await sendRequest(path: context, payload: payload)
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
    
    public func interrupt() async -> Bool {
        return await sendPostRequest(path: "interrupt")
    }
    
    public func skip() async -> Bool {
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

    func refreshCheckpoints() async -> Bool {
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
        
    private func sendPostRequest(path: String, payload: [String: Any] = [:]) async -> Bool {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            return false
        }
        
        do {
            let (data, nsHttpUrlResponse) = try await session.data(for: request)
            if let httpResponse = nsHttpUrlResponse as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print(String(data: data, encoding: .utf8) ?? "Could not convert data to string")
                    return true
                }
            }
            return false
        } catch {
            print("Error sending POST request: \(error)")
            return false
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
        request.timeoutInterval = 300
        
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
