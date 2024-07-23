import Foundation
struct Lora: Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    
    static func == (lhs: Lora, rhs: Lora) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
    }
}
