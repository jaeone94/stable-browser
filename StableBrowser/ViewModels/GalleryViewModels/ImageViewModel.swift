import SwiftUI
import RealmSwift

class ImageViewModel: ObservableObject {
    static let shared = ImageViewModel()
    // Properties For Image Viewer...
    @Published var showImageViewer = false
    @Published var triggerLoadThumbnails: Bool = false
    @Published var sortDescending: Bool = true

    @Published var selectedAlbum: Album?
    @Published var selectedIndex: Int = 0
    @Published var selectedPhotos: [OpenPhoto] = []
    
        
    func sortPhotos() {
        if sortDescending {
            selectedPhotos.sort(by: { $0.createdAt > $1.createdAt })
        } else {
            selectedPhotos.sort(by: { $0.createdAt < $1.createdAt })
        }
        triggerLoadThumbnails.toggle()
    }
    
    func getPhotos(album: Album) -> [OpenPhoto] {
        let securePhotos = Array(album.photos)
        var photos: [OpenPhoto] = []
        for photo in securePhotos {
            photos.append(OpenPhoto(photo: photo))
        }
        return photos
    }    
}


