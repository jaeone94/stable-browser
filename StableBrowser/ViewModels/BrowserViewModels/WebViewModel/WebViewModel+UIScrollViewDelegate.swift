import UIKit

extension WebViewModel: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scroll = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        updateScrollDirection(with: scroll.y)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        handleRefreshControl(for: scrollView)
    }
    
    // MARK: - Private Methods
    
    private func updateScrollDirection(with scrollY: CGFloat) {
        onScrollUp = scrollY > 0
        onScrollDown = scrollY < 0
    }
    
    private func handleRefreshControl(for scrollView: UIScrollView) {
        if let refreshControl = scrollView.refreshControl, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
            refresh()
        }
    }
}
