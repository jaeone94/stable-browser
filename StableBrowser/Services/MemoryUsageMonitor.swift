import Foundation
import UIKit

class MemoryUsageMonitor: ObservableObject {
    @Published var isMemoryWarningPresented = false
    private let memoryWarningThreshold: Double = 0.7 // 70%
    private var timer: Timer?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(startMonitoring), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopMonitoring), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        startMonitoring() // Start monitoring immediately
    }
    
    @objc func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    @objc func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func handleMemoryWarning() {
        DispatchQueue.main.async {
            self.isMemoryWarningPresented = true
        }
    }
    
    private func checkMemoryUsage() {
        let usedMemory = Double(reportMemoryUsage())
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let memoryUsagePercentage = usedMemory / totalMemory
                
        if memoryUsagePercentage > memoryWarningThreshold {
            print("Total Memory: \(totalMemory / (1024 * 1024)) MB")
            print("Used Memory: \(usedMemory / (1024 * 1024)) MB")
            print("Memory Usage: \(memoryUsagePercentage * 100)%")
            DispatchQueue.main.async {
                self.isMemoryWarningPresented = true
            }
        }else {
            DispatchQueue.main.async {
                self.isMemoryWarningPresented = false
            }
        }
    }
    
    private func reportMemoryUsage() -> Int64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        return Int64(taskInfo.phys_footprint)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
