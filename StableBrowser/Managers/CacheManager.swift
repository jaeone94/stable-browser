import Foundation

class CacheManager {
    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ResultMaps")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func saveResultMap(_ resultMap: WebUIApiResult, for contextID: UUID) {
        let fileURL = cacheDirectory.appendingPathComponent(contextID.uuidString)
        do {
            let data = try JSONEncoder().encode(resultMap)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save resultMap: \(error)")
        }
    }
    
    func loadResultMap(for contextID: UUID) -> WebUIApiResult? {
        let fileURL = cacheDirectory.appendingPathComponent(contextID.uuidString)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(WebUIApiResult.self, from: data)
        } catch {
            print("Failed to load resultMap: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}
