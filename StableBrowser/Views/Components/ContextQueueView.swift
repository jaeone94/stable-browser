import SwiftUI

struct ContextQueueView: View {
    var parent: StableBrowserApp
    @StateObject var queueManager = ContextQueueManager.shared
    @State internal var isMinimized = true {
        didSet {
            if isMinimized {
                cancelMinimizeTimer()
                startDarkenTimer()
            }else {
                withAnimation {
                    isDarkened = false
                }
                cancelDarkenTimer()
                startMinimizeTimer()
            }
        }
    }
    @State private var dragOffset: CGSize = .zero
    @StateObject private var memoryMonitor = MemoryUsageMonitor()

    // Darker (less transparent) 3 seconds after minimised
    @State private var isDarkened = true
    @State private var darkenTimer: Timer?
    @State private var minimizeTimer: Timer?
    
    var isPortraitMode: Bool {
        UIDevice.current.userInterfaceIdiom != .pad && verticalSizeClass == .regular
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        VStack {
            if !isPortraitMode { Spacer() }
            
            VStack {
                if !isPortraitMode { Spacer() }
                
                if memoryMonitor.isMemoryWarningPresented {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.red)
                                .frame(width: 10, height: 10)
                            
                            Text("The app is using a high amount of memory")
                            Spacer()
                        }
                        HStack {
                            Text("Please consider closing some content or restarting the app.")
                                .padding(.leading, 10)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 100)
                    .foregroundColor(Color.black.opacity(0.8))
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                }
                
                completedContextsView
                    .onTapGesture(perform: handleTap)
                queueItemsView
                    .onTapGesture(perform: handleTap)
                
                if isPortraitMode { Spacer() }
            }
            .opacity(isDarkened ? 0.5 : 1)
            .animation(.spring(), value: queueManager.queue.map { $0.id })
            .gesture(minimizeGesture)
            .frame(height: 300)
            .padding(.vertical, 5)
            
            if isPortraitMode { Spacer() }
        }
        .onChange(of: queueManager.historyQueue, { oldValue, newValue in
            withAnimation {
                self.isMinimized = false
            }
        })
        .environmentObject(queueManager)
    }
    
    private func handleLeftSwipe() {
        if queueManager.queue.count > 2 {
            queueManager.cancelAllIdleContexts()
        } else if queueManager.queue.count == 1 {
            if let context = queueManager.queue.first, context.state == .idle {
                queueManager.cancelContext(context)
            }
        }
    }
    
    private var completedContextsView: some View {
        Group {
            if queueManager.getCompletedContexts().count > 0 {
                if !(isMinimized && !queueManager.queue.isEmpty) {
                    statusView(color: getLastStateColor(), text: !isMinimized ? "Generation results : \(queueManager.getCompletedContexts().count)" : nil)
                }
            }
        }
    }
    
    private var queueItemsView: some View {
        Group {
            if !isMinimized {
                if queueManager.queue.count == 2 {
                    ContextItemView(parent: self, context: queueManager.queue[1])
                } else if queueManager.queue.count > 2 {
                    statusView(color: .gray, text: "+\(queueManager.queue.count - 1)", subtext: "Idle")
                }
            }
            
            ForEach(queueManager.queue.prefix(1), id: \.id) { context in
                ContextItemView(parent: self, context: context)
            }
        }
    }
    
    private func statusView(color: Color, text: String?, subtext: String? = nil) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            if let text = text {
                Text(text)
                Spacer()
            }
            if let subtext = subtext {
                Text(subtext)
            }
        }
        .padding(.horizontal)
        .frame(height: 40)
        .foregroundColor(Color.black.opacity(0.8))
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
        .offset(color == .gray ? dragOffset : .zero)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { gesture in
                    withAnimation {self.isMinimized = false}
                    if color == .gray && text?.hasPrefix("+") == true {
                        self.dragOffset.width = gesture.translation.width > 0 ? 0 : gesture.translation.width
                    }
                    withAnimation {
                        self.isMinimized = isPortraitMode ? gesture.translation.height < -20 : gesture.translation.height > 20
                    }
                }
                .onEnded { gesture in
                    if color == .gray && text?.hasPrefix("+") == true {
                        if self.dragOffset.width < -50 {
                            queueManager.cancelAllIdleContexts()
                        }
                    }
                    withAnimation {
                        self.dragOffset = .zero
                    }
                }
            )
    }
    
    private var minimizeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { gesture in
                withAnimation {
                    self.isMinimized = isPortraitMode ? gesture.translation.height < -20 : gesture.translation.height > 20
                }
            }
    }
    
    private func handleTap() {
        if isMinimized {
            withAnimation {
                self.isMinimized = false
            }
        } else {
            withAnimation {
                self.parent.showHistoryView = true
                self.isMinimized = true
            }
        }
    }
    
    private func startDarkenTimer() {
        cancelDarkenTimer() // Cancel an existing timer if it exists
        darkenTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            withAnimation {
                self.isDarkened = true
            }
        }
    }

    private func cancelDarkenTimer() {
        darkenTimer?.invalidate()
        darkenTimer = nil
    }
    
    private func startMinimizeTimer() {
        cancelMinimizeTimer() // Cancel an existing timer if it exists
        minimizeTimer = Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { _ in
            withAnimation {
                self.isMinimized = true
            }
        }
    }

    private func cancelMinimizeTimer() {
        minimizeTimer?.invalidate()
        minimizeTimer = nil
    }
    
    private func getLastStateColor() -> Color {
        if let state = queueManager.getCompletedContexts().last?.state {
            switch state {
            case .idle: return .gray
            case .ready: return .blue
            case .inProgress: return .blue
            case .completed: return .green
            case .error: return .red
            case .canceled: return .purple
            case .stopped: return .orange
            case .stopping: return .yellow
            }
        }else {
            return .green
        }
    }
}

struct ContextItemView: View {
    var parent: ContextQueueView
    @ObservedObject var context: StableGenerationContext
    @EnvironmentObject var queueManager: ContextQueueManager
    @State private var offset: CGFloat = 0
    
    var body: some View {
        VStack {
            HStack {
                statusIndicator
                if !parent.isMinimized {
                    Text(context.type.description)
                    Spacer()
                    Text(context.state.description)
                }
            }
            if !parent.isMinimized && context.state == .inProgress {
                progressView
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: context.progress)
        .padding(.horizontal)
        .frame(height: !parent.isMinimized && context.state == .inProgress ? 80 : 40)
        .foregroundColor(Color.black.opacity(0.8))
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    withAnimation {self.parent.isMinimized = false}
                    if context.state == .idle || context.state == .inProgress {
                        self.offset = gesture.translation.width > 0 ? 0 : gesture.translation.width
                    }
                    
                }
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        if context.state == .idle {
                            queueManager.cancelContext(context)
                        }else if context.state == .inProgress {
                            queueManager.stopContext(context)
                        }
                    }else {
                        withAnimation {
                            self.parent.isMinimized = self.parent.isPortraitMode ? gesture.translation.height < -20 : gesture.translation.height > 20
                        }
                    }
                    
                    withAnimation {
                        self.offset = 0
                    }
                }
        )
    }
    
    private var statusIndicator: some View {
        Group {
            if context.state == .inProgress {
                ProgressView(value: context.progress, total: 1)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .frame(width: 10, height: 10)
            } else {
                Circle()
                    .fill(stateColor)
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private var progressView: some View {
        HStack {
            ProgressView(value: context.progress, total: 1)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.leading, 10)
            Spacer()
            Text("\(Int(context.progress * 100))%")
        }
    }
    
    private var stateColor: Color {
        switch context.state {
            case .idle: return .gray
            case .ready: return .blue
            case .inProgress: return .blue
            case .completed: return .green
            case .error: return .red
            case .canceled: return .purple
            case .stopped: return .orange
            case .stopping: return .yellow
        }
    }
}
