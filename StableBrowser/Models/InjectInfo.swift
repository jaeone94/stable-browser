import Foundation
import RealmSwift

class InjectInfo: Object, Identifiable{
    @Persisted(primaryKey: true) var id: ObjectId = ObjectId.generate()
    @Persisted var baseUrl: String
    @Persisted var src: String
    @Persisted var dest: String

    convenience init(baseUrl: String, src: String, dest: String) {
        self.init()
        self.baseUrl = baseUrl
        self.src = src
        self.dest = dest
    }
}

struct InjectInfoDTO: Codable {
    let baseUrl: String
    let src: String
    let dest: String
}
