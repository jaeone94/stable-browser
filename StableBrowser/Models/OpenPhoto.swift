import RealmSwift

class OpenPhoto: Identifiable, Equatable {
    var id: ObjectId
    var name: String
    var image: UIImage
    var thumbNail: UIImage
    var sourceImage: UIImage?
    var metaData: [String: Any]
    var createdAt: Date
    
    init(photo: SecurePhoto) {
        self.id = photo.id
        self.name = photo.name
        if let photoData = photo.getPhotoData() {
            self.image = UIImage(data: photoData) ?? UIImage(systemName: "photo")!
        } else {
            self.image = UIImage(systemName: "photo")!
        }

        if let thumbNailData = photo.getThumbnailData() {
            self.thumbNail = UIImage(data: thumbNailData) ?? UIImage(systemName: "photo")!
        }else {
            self.thumbNail = UIImage(systemName: "photo")!
        }
        self.metaData = photo.getMetadata() ?? [:]
        self.createdAt = photo.createdAt
        if let sourceImageData = photo.getSourcePhotoData() {
            self.sourceImage = UIImage(data: sourceImageData) ?? nil
        }else {
            self.sourceImage = nil
        }
    }

    static func == (lhs: OpenPhoto, rhs: OpenPhoto) -> Bool {
        return lhs.id == rhs.id
    }
}

class OpenThumbNailPhoto: Identifiable, Equatable {
    var id: ObjectId
    var thumbNail: UIImage
    var createdAt: Date
    
    init(id: ObjectId, thumbNail: UIImage, createdAt: Date) {
        self.id = id
        self.thumbNail = thumbNail
        self.createdAt = createdAt
    }

    static func == (lhs: OpenThumbNailPhoto, rhs: OpenThumbNailPhoto) -> Bool {
        return lhs.id == rhs.id
    }
}
