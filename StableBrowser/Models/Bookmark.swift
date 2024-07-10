import Foundation

struct Bookmark: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var url: String
    // favicon is a base64 encoded string
    var favicon: String = ""
}

extension Bookmark: Equatable {
    static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        return lhs.id == rhs.id
    }
}
