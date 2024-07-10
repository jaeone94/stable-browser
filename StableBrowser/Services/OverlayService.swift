import Foundation
import SwiftUI


class OverlayService: ObservableObject {
    static let shared = OverlayService()
    @Published var isSpinnerVisible: Bool = false
    
    func showOverlaySpinner() {
        withAnimation{
            isSpinnerVisible = true
        }
    }
    
    func hideOverlaySpinner() {
        withAnimation{
            isSpinnerVisible = false
        }
    }
}

