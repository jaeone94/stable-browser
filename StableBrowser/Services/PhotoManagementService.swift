import RealmSwift
import SwiftUI
import CryptoKit

class PhotoManagementService: ObservableObject {
    static let shared = PhotoManagementService()
    private let realm = try! Realm()
    
    @Published var isNewAlbumDialogVisible: Bool = false
    @Published var newAlbumName: String = ""
    @Published var newSecuredPhotoQueue: SecurePhoto? = nil
    @Published var toggleRedrawAlbumList: Bool = false
    
    @Published var unlockedAlbums: [ObjectId : Bool] = [:]
    @Published var albums: [Album] = []
    
    init() {
        getAllAlbums { albums in
            self.albums = albums
            for album in albums {
                self.unlockedAlbums[album.id] = false
            }
        }
    }
    
    func getAllAlbums(completion: @escaping ([Album]) -> Void) {
        DispatchQueue.main.async {
            let albums = Array(self.realm.objects(Album.self))
            completion(albums)
        }
    }


    @MainActor func addAlbum(name: String, isSecret: Bool, password: String? = nil) {
        let newAlbum = Album()
        newAlbum.name = name
        newAlbum.isSecret = isSecret
        newAlbum.createdAt = Date()
        try! realm.write {
            realm.add(newAlbum)
        }
        
        if let newSecuredPhoto = newSecuredPhotoQueue {
            try! realm.write {
                newAlbum.photos.append(newSecuredPhoto)
                self.newSecuredPhotoQueue = nil
                Toast.shared.present(
                    title: "Image successfully saved",
                    symbol: "photo.badge.checkmark.fill",
                    isUserInteractionEnabled: true,
                    timing: .medium,
                    padding: 140
                )
            }
        }
        if isSecret {
            if let password = password {
                try! realm.write {
                    let data = password.data(using: .utf8)
                    let sha256 = SHA256.hash(data: data!)
                    let shaString = sha256.compactMap{String(format: "%02x", $0)}.joined()
                    newAlbum.password = shaString
                }
            }
        }
        unlockedAlbums[newAlbum.id] = true
        albums.append(newAlbum)
    }
    
    @MainActor func updateAlbum(album: Album, name: String, isSecret: Bool, password: String? = nil) {
        try! realm.write {
            album.name = name
            album.isSecret = isSecret
        }
        
        if isSecret {
            if let password = password {
                try! realm.write {
                    let data = password.data(using: .utf8)
                    let sha256 = SHA256.hash(data: data!)
                    let shaString = sha256.compactMap{String(format: "%02x", $0)}.joined()
                    album.password = shaString
                }
            }
            unlockedAlbums[album.id] = false
        }else {
            unlockedAlbums[album.id] = true
        }
        
    }
    
    @MainActor func deleteAlbum(Album: Album, completion: @escaping (Bool) -> Void) {
        do {
            try realm.write {
                realm.delete(Album.photos)
                realm.delete(Album)
                completion(true)
            }
        } catch {
            print("An error occurred while delete album: \(error)")
            completion(false)
        }
    }
    
    @MainActor func addPhotoToAlbum(album: Album, photo: SecurePhoto, completion: @escaping (Bool) -> Void) {
        do {
            try realm.write {
                album.photos.append(photo)
                completion(true)
            }
        } catch {
            print("An error occurred while adding the photo to the album: \(error)")
            completion(false)
        }
    }
    
    @MainActor func addPhotosToAlbum(Album: Album, photos: [SecurePhoto]) {
        try! realm.write {
            Album.photos.append(objectsIn: photos)
        }
    }
    
    @MainActor func addPhotoToNewAlbum(photo: SecurePhoto) {
        newSecuredPhotoQueue = photo
        showNewAlbumDialog()
    }
    
    @MainActor func movePhotoToAlbum(photo: SecurePhoto, fromAlbum: Album, toAlbum: Album) {
        try! realm.write {
            fromAlbum.photos.remove(at: fromAlbum.photos.index(of: photo)!)
            toAlbum.photos.append(photo)
        }
    }

    @MainActor func copyPhotoToAlbum(photo: SecurePhoto, toAlbum: Album) {
        try! realm.write {
            photo.id = ObjectId.generate()
            photo.createdAt = Date()
            toAlbum.photos.append(photo)
        }
    }
            
    
    @MainActor func showNewAlbumDialog() {
        withAnimation{
            isNewAlbumDialogVisible = true
        }
    }
    
    @MainActor func hideNewAlbumDialog() {
        withAnimation{
            isNewAlbumDialogVisible = false
        }
    }
    
    
    @MainActor func deletePhotoFromAlbum(Album: Album, photo: SecurePhoto) {
        if let index = Album.photos.index(of: photo) {
            try! realm.write {
                Album.photos.remove(at: index)
            }
        }
    }
    
    @MainActor func deletePhotoFromAlbum(Album: Album, id: ObjectId) {
        if let photo = Album.photos.first(where: { $0.id == id }) {
            try! realm.write {
                Album.photos.remove(at: Album.photos.index(of: photo)!)
            }
        }
    }
    
    @MainActor func deletePhotosFromAlbum(Album: Album, photos: [SecurePhoto]) {
        try! realm.write {
            for photo in photos {
                if let index = Album.photos.index(of: photo) {
                    Album.photos.remove(at: index)
                }
            }
        }
    }

    func tryUnlockAlbum(album: Album, password: String, completion: @escaping (Bool) -> Void) {
        if let albumPassword = album.password {
            let data = password.data(using: .utf8)
            let sha256 = SHA256.hash(data: data!)
            let shaString = sha256.compactMap{String(format: "%02x", $0)}.joined()
            if albumPassword == shaString {
                unlockedAlbums[album.id] = true
                completion(true)
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    func unlockAlbum(album: Album, completion: @escaping (Bool) -> Void) {
        unlockedAlbums[album.id] = true
        completion(true)
    }
}
