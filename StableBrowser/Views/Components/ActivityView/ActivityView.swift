import SwiftUI
import LinkPresentation
import CoreServices
import SwiftUI
import LinkPresentation
import CoreServices

class ImageActivityItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let title: String
    let createdAt: String
    
    init(image: UIImage, title: String, createdAt: Date) {
        self.image = image
        self.title = title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
        self.createdAt = dateFormatter.string(from: createdAt)
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        return image
    }
    
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return title
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metaData = LPLinkMetadata()
        metaData.title = title + "( " + createdAt + " )"
        metaData.imageProvider = NSItemProvider(object: image)
        metaData.iconProvider = NSItemProvider(object: image)
        return metaData
    }
}

struct ActivityView: UIViewControllerRepresentable {
    @Binding var item: ActivityItem?
    var permittedArrowDirections: UIPopoverArrowDirection
    var completion: UIActivityViewController.CompletionWithItemsHandler?

    func makeUIViewController(context: Context) -> ActivityViewControllerWrapper {
        let controller = ActivityViewControllerWrapper(
            item: $item,
            permittedArrowDirections: permittedArrowDirections,
            completion: completion
        )
        return controller
    }

    func updateUIViewController(_ controller: ActivityViewControllerWrapper, context: Context) {
        controller.item = $item
        controller.completion = completion
        controller.updateState()
    }
}

final class ActivityViewControllerWrapper: UIViewController {
    var item: Binding<ActivityItem?>
    var permittedArrowDirections: UIPopoverArrowDirection
    var completion: UIActivityViewController.CompletionWithItemsHandler?
    
    init(
        item: Binding<ActivityItem?>,
        permittedArrowDirections: UIPopoverArrowDirection,
        completion: UIActivityViewController.CompletionWithItemsHandler?)
    {
        self.item = item
        self.permittedArrowDirections = permittedArrowDirections
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateState() {
        if let activityItem = item.wrappedValue {
            if presentedViewController == nil {
                let activityItems = activityItem.images.map { ImageActivityItemSource(image: $0.image, title: $0.name, createdAt: $0.createdAt) }
                let controller = UIActivityViewController(
                    activityItems: activityItems,
                    applicationActivities: activityItem.activities
                )
                controller.excludedActivityTypes = activityItem.excludedTypes
                controller.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
                controller.popoverPresentationController?.sourceView = self.view
                controller.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                
                controller.completionWithItemsHandler = { [weak self] (activityType, success, items, error) in
                    self?.item.wrappedValue = nil
                    self?.completion?(activityType, success, items, error)
                }
                
                present(controller, animated: true)
            }
        }
    }
}

extension View {
    
    /// Shows the corresponding activity sheet when a related `ActivityItem` exists.
    /// - Parameters:
    ///   - item: The item to use for the activity.
    ///   - permittedArrowDirections: The permitted arrow directions for the popover on iPad.
    ///   - onComplete: Called with the result, when the sheet is dismissed.
    func activitySheet(_ item: Binding<ActivityItem?>, permittedArrowDirections: UIPopoverArrowDirection = .any, onComplete: UIActivityViewController.CompletionWithItemsHandler? = nil) -> some View {
        let isPresented = Binding<Bool>(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
        return background(
            ActivityView(item: item, permittedArrowDirections: permittedArrowDirections, completion: onComplete)
                .opacity(isPresented.wrappedValue ? 1 : 0)
        )        
    }
}
