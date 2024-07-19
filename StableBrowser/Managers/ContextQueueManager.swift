import Foundation
import Combine

class ContextQueueManager: ObservableObject {
    static let shared = ContextQueueManager()
    
    @Published private(set) var queue: [StableGenerationContext] = []
    @Published private(set) var historyQueue: [StableGenerationContext] = []
    var completedHistoryQueue: [StableGenerationContext] {
        get {
            return self.historyQueue.filter { $0.state == .completed || $0.state == .stopped || $0.state == .error }
        }
    }
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "com.app.contextQueueManager", qos: .background)
    
    // Add a Set to store subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func addContext(_ context: StableGenerationContext) {
        self.queue.append(context)
        processingQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.historyQueue.append(context)
                self?.observeContext(context)
            }
            self?.processNextContext()
        }
    }

    private func observeContext(_ context: StableGenerationContext) {
        context.$state.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
    }

    
    func removeContext(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, index < self.queue.count else { return }
            let context = self.queue.remove(at: index)
            DispatchQueue.main.async {
                context.state = .canceled
            }
        }
    }
    
    func removeContextOnHistoryQueue(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, index < self.historyQueue.count else { return }
            let context = self.historyQueue.remove(at: index)            
        }
    }
    
    func clearHistoryQueue() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for context in self.historyQueue {
                if context.state == .inProgress {
                    stopContext(context)
                }else if context.state == .idle {
                    cancelContext(context)
                }
            }
            self.historyQueue.removeAll()
        }
    }
    
    func cancelContext(_ context: StableGenerationContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.queue.firstIndex(where: { $0.id == context.id }) {
                let canceledContext = self.queue.remove(at: index)
                DispatchQueue.main.async {
                    canceledContext.state = .canceled
                    self.objectWillChange.send()
                }
                self.processNextContext()
            }
        }
    }
    
    func cancelAllIdleContexts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let canceledContexts = self.queue.filter { $0.state == .idle }
            self.queue.removeAll { $0.state == .idle }
            DispatchQueue.main.async {
                for context in canceledContexts {
                    context.state = .canceled
                }
                self.objectWillChange.send()
            }
            self.processNextContext()
        }
    }
    
    func stopContext(_ context: StableGenerationContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.queue.firstIndex(where: { $0.id == context.id }) != nil {
                context.stop()
            }
        }
    }

    
    func getHistoryQueue() -> [StableGenerationContext] {
        return historyQueue
    }

    func getCompletedContexts() -> [StableGenerationContext] {
        return historyQueue.filter { $0.state == .completed || $0.state == .stopped || $0.state == .error }
    }
    
    private func processNextContext() {
        guard !isProcessing else { return }
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.isProcessing = true
            
            while !self.queue.isEmpty {
                let context = self.queue[0]
                
                switch context.state {
                case .idle:                    
                    context.state = .ready
                    self.generateContext(context)
                case .completed, .stopped, .error, .canceled:
                    self.queue.removeFirst()
                    
                    continue
                default:
                    break
                }
                
                break
            }
            
            self.isProcessing = false
        }
    }
    
    private func generateContext(_ context: StableGenerationContext) {
        context.generate()
        
        // Observe state changes
        let observation = context.$state.sink { [weak self] state in
            if state == .completed || state == .stopped || state == .error {
                DispatchQueue.main.async { [weak self] in
                    self?.queue.removeFirst()
                    self?.processNextContext()
                }
            }
        }
        
        // Store observation to avoid premature deallocation
        objc_setAssociatedObject(context, "stateObservation", observation, .OBJC_ASSOCIATION_RETAIN)
    }
}
