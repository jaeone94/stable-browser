import RealmSwift

class Album: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId // Unique key
    @Persisted var name: String // Album name
    @Persisted var thumbnail: SecurePhoto? // Thumbnail photo
    @Persisted var createdAt: Date // Creation date
    @Persisted var isSecret: Bool // Indicates if the album is secret
    @Persisted var password: String? // Password stored as SHA256 hash
    @Persisted var photos: List<SecurePhoto> // Photos inside the album
    
    func updateThumbnail() {
        // update thumbnail with the last photo using createdAt
        let sortedPhotos = photos.sorted(byKeyPath: "createdAt", ascending: false)
        thumbnail = sortedPhotos.first        
    }
}
