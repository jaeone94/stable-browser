import Foundation
import SwiftUI

class Tab: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var interactionState: Data?
    var snapshot: String? // base64 encoded snapshot of the webview. it will change when the page changes
    var snapshot_id: UUID?

    var currentPageIndex: Int = 0
        
    // Initializer
    init() {
        //Create Empty Tab
        self.title = ""
        self.url = ""
    }

    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
        
    // When assigning
    func updateInteractionState(interactionState: Any?) {
        self.interactionState = interactionState as? Data
    }

    func restoreInteractionState() -> Data? {
        return interactionState
    }
    
    func changePage(title: String, url: String) {
        self.title = title
        self.url = url
    }
}
extension Tab: Equatable {
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.id == rhs.id
    }
}


