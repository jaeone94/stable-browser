import RealmSwift

class Album: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId // Unique key
    @Persisted var name: String // Album name
    @Persisted var thumbnail: SecurePhoto? // Thumbnail photo
    @Persisted var createdAt: Date // Creation date
    @Persisted var isSecret: Bool // Indicates if the album is secret
    @Persisted var password: String? // Password stored as SHA256 hash
    @Persisted var photos: List<SecurePhoto> // Photos inside the album
}
