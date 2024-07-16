import UIKit

/// The activity used to bring up the `ActivityView` via the `activitySheet` modifier
struct ActivityItem {
    var images: [OpenPhoto]
    var activities: [UIActivity]
    var excludedTypes: [UIActivity.ActivityType]
    
    init(
        images: [OpenPhoto],
        activities: [UIActivity] = [],
        excludedTypes: [UIActivity.ActivityType] = []
    ) {
        self.images = images
        self.activities = activities
        self.excludedTypes = excludedTypes
    }
}
