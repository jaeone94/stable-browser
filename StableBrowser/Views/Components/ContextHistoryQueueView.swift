import SwiftUI

struct ContextHistoryQueueView: View {
    @StateObject var queueManager = ContextQueueManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                if queueManager.historyQueue.isEmpty {
                    Section {
                        Text("No generation results")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                            .padding()
                    }
                }else {
                    ForEach(queueManager.historyQueue.reversed(), id: \.id) { context in
                        ContextHistoryItemView(context: context)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive, action: {
                                    onDeleteContext(context)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .transition(.opacity)
            .animation(.easeInOut, value: queueManager.historyQueue)
            .navigationBarTitle("GENERATION RESULTS", displayMode: .inline)
            .navigationBarItems(leading: Button("Back") {
                isPresented = false
            }, trailing: Button("Clear") {
                queueManager.clearHistoryQueue()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    func onDeleteContext(_ context: StableGenerationContext) {
        if let index = queueManager.historyQueue.firstIndex(of: context) {
            switch context.state {
            case .idle:
                queueManager.cancelContext(context)
                queueManager.removeContextOnHistoryQueue(at: index)
                break
            case .inProgress:
                queueManager.stopContext(context)
                queueManager.removeContextOnHistoryQueue(at: index)
                break
            default:
                queueManager.removeContextOnHistoryQueue(at: index)
                break
            }
        }
    }
}

struct ContextHistoryItemView: View {
    @ObservedObject var context: StableGenerationContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                statusIndicator
                if context.state == .completed || context.state == .stopped {
                    VStack(alignment: .leading) {
                        Text(context.type.description)
                            .font(.headline)
                        Text(context.state.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }else {
                    HStack(alignment: .center) {
                        Text(context.type.description)
                            .font(.headline)
                        Spacer()
                        Text(context.state.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let firstImage = context.resultMap?.images.first,
                   let uiImage = ImageUtils.base64ToImage(firstImage) {
                    let resultImages = context.getResultImages()
                    let sourceImage = context.getInitImage()
                    NavigationLink(destination: ResultImageView(resultImages: resultImages, sourceImage: sourceImage)) {
                        HStack {
                            Spacer()
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            if context.state == .inProgress {
                HStack {
                    ProgressView(value: context.progress, total: 1)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.leading, 10)
                    Spacer()
                    Text("\(Int(context.progress * 100))%")
                    // Stop Button
                    
                    Image(systemName: "stop.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                        .onTapGesture {
                            withAnimation {
                                ContextQueueManager.shared.stopContext(context)
                            }
                        }
                    
                }.padding(.top, 5)
                .padding(.horizontal, 5)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: context.state)
        .padding(.vertical, 8)
        .frame(height: itemHeight)
    }
    
    private var statusIndicator: some View {
        Group {
            if context.state == .inProgress {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(stateColor)
                    .frame(width: 12, height: 12)
            }
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
    
    private var itemHeight: CGFloat {
        switch context.state {
        case .completed, .stopped, .stopping:
            return 60
        case .inProgress:
            return 60
        default:
            return 30
        }
    }
}
