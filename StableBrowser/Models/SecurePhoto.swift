import SwiftUI
import Foundation
import RealmSwift
import CryptoKit

class SecurePhoto: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId = ObjectId.generate()
    @Persisted var name: String
    @Persisted private var photoData: Data // Encrypted photo data
    @Persisted private var metadata: Data // Encrypted metadata
    @Persisted private var thumbnailData: Data // Resized preview image data
    @Persisted var createdAt: Date = Date()
    @Persisted private var sourcePhotoData: Data? // Original photo data (optional)

    convenience init(name: String, photoData: Data, thumbnailData: Data, metadata: [String: Any], sourcePhotoData: Data? = nil) {
        self.init()
        
        self.name = name

        guard let keyData = AuthenticationService.shared.getEncryptionKey() else { return }
        let key = SymmetricKey(data: keyData)
        
        // Encrypt photo data
        do {
            let sealedBox = try AES.GCM.seal(photoData, using: key)
            self.photoData = sealedBox.combined ?? Data()
        } catch {
            print("Failed to encrypt photo data: \(error)")
        }

        // Encrypt thumbnail data
        do {
            let sealedBox = try AES.GCM.seal(thumbnailData, using: key)
            self.thumbnailData = sealedBox.combined ?? Data()
        } catch {
            print("Failed to encrypt thumbnail data: \(error)")
        }

        // Encrypt metadata
        do {
            let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: [])
            let sealedBox = try AES.GCM.seal(metadataData, using: key)
            self.metadata = sealedBox.combined ?? Data()
        } catch {
            print("Failed to encrypt metadata: \(error)")
        }

        if let sourcePhotoData = sourcePhotoData {
            do {
                let sealedBox = try AES.GCM.seal(sourcePhotoData, using: key)
                self.sourcePhotoData = sealedBox.combined ?? Data()
            } catch {
                print("Failed to encrypt metadata: \(error)")
            }
        }
    }

    func getData() -> (photoData: Data?, thumbnailData: Data?, metadata: [String: Any]?) {
        guard let keyData = AuthenticationService.shared.getEncryptionKey() else { return (nil, nil, nil) }
        let key = SymmetricKey(data: keyData)

        // Decrypt photo data
        var decryptedPhotoData: Data? = nil
        if let box = try? AES.GCM.SealedBox(combined: photoData),
           let data = try? AES.GCM.open(box, using: key) {
            decryptedPhotoData = data
        }

        // Decrypt thumbnail data
        var decryptedThumbnailData: Data? = nil
        if let box = try? AES.GCM.SealedBox(combined: thumbnailData),
           let data = try? AES.GCM.open(box, using: key) {
            decryptedThumbnailData = data
        }

        // Decrypt metadata
        var decryptedMetadata: [String: Any]? = nil
        if let metadataBox = try? AES.GCM.SealedBox(combined: metadata),
           let metadataData = try? AES.GCM.open(metadataBox, using: key),
           let metadata = try? JSONSerialization.jsonObject(with: metadataData, options: []) as? [String: Any] {
            decryptedMetadata = metadata
        }

        return (decryptedPhotoData, decryptedThumbnailData, decryptedMetadata)
    }

    func getPhotoData() -> Data? {
        guard let keyData = AuthenticationService.shared.getEncryptionKey() else { return nil }
        let key = SymmetricKey(data: keyData)

        // Decrypt photo data
        var decryptedPhotoData: Data? = nil
        if let box = try? AES.GCM.SealedBox(combined: photoData),
           let data = try? AES.GCM.open(box, using: key) {
            decryptedPhotoData = data
        }

        return decryptedPhotoData
    }
    
    func getSourcePhotoData() -> Data? {
        guard let keyData = AuthenticationService.shared.getEncryptionKey() else { return nil }
        let key = SymmetricKey(data: keyData)

        // Decrypt source photo data
        var decryptedPhotoData: Data? = nil
        
        if let sourcePhotoData = sourcePhotoData, let box = try? AES.GCM.SealedBox(combined: sourcePhotoData),
           let data = try? AES.GCM.open(box, using: key) {
            decryptedPhotoData = data
        }

        return decryptedPhotoData
    }

    func getThumbnailData() -> Data? {
        guard let keyData = AuthenticationService.shared.getEncryptionKey() else { return nil }
        let key = SymmetricKey(data: keyData)

        var decryptedThumbnailData: Data? = nil
        do {
            let realm = try Realm()
            let thumbnailData = realm.object(ofType: SecurePhoto.self, forPrimaryKey: id)?.thumbnailData ?? Data()
            if let box = try? AES.GCM.SealedBox(combined: thumbnailData),
               let data = try? AES.GCM.open(box, using: key) {
                decryptedThumbnailData = data
            }
        } catch {
            print("Error accessing Realm: \(error)")
        }

        return decryptedThumbnailData
    }

    func getMetadata() -> [String: Any]? {
        guard let keyData = AuthenticationService.shared.getEncryptionKey() else { return nil }
        let key = SymmetricKey(data: keyData)

        // Decrypt metadata
        var decryptedMetadata: [String: Any]? = nil
        if let metadataBox = try? AES.GCM.SealedBox(combined: metadata),
           let metadataData = try? AES.GCM.open(metadataBox, using: key),
           let metadata = try? JSONSerialization.jsonObject(with: metadataData, options: []) as? [String: Any] {
            decryptedMetadata = metadata
        }

        return decryptedMetadata
    }
}
