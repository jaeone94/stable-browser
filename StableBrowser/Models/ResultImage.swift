import UIKit

class ResultImage: Identifiable {
    var id = UUID()
    var image: UIImage
    var info: [String: Any]
    var seed: Int
    var subSeed: Int
    
    init(id: UUID = UUID(), image: UIImage, info: [String : Any], seed: Int, subSeed: Int) {
        self.id = id
        self.image = image
        self.info = info
        self.seed = seed
        self.subSeed = subSeed
    }
}
