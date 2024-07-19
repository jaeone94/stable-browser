import UIKit

struct WebUIApiResult: Encodable, Decodable {
    let images: [String]
    let parameters: [String: String]
    let info: [String: String]
    let json: [String: String]
    
    var image: String? {
        return images.first
    }
    
    // 커스텀 이니셜라이저
    init(images: [UIImage], parameters: [String: Any], info: [String: Any], json: [String: Any]) {
        self.images = images.compactMap { $0.pngData()?.base64EncodedString() }
        self.parameters = parameters.mapValues { "\($0)" }
        self.info = info.mapValues { "\($0)" }
        self.json = json.mapValues { "\($0)" }
    }
    
    // Encodable 준수를 위한 encode 메서드
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(images, forKey: .images)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(info, forKey: .info)
        try container.encode(json, forKey: .json)
    }
    
    private enum CodingKeys: String, CodingKey {
        case images, parameters, info, json
    }
}
