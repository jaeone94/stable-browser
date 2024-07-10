import SwiftUI

struct SDModelSettingView: View {
    var parent: StableSettingsView
    var title: String
    var modelName: String?
    var key: String
    @State private var selected = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        let sdModels = parent.stableSettingViewModel.sdModels
        List {
            ForEach(0..<sdModels.count, id: \.self) { index in
                Button(action: {
                    OverlayService.shared.showOverlaySpinner()
                    presentationMode.wrappedValue.dismiss()
                    parent.stableSettingViewModel.setSDModel(model: sdModels[index].model_name ?? "")
                }) {
                    HStack {
                        Text(sdModels[index].title ?? "")
                        Spacer()
                    }
                    .foregroundColor(selected == index ? .blue : .primary)
                }
                .contentShape(Rectangle())
                .buttonStyle(PlainButtonStyle()) 
            }
        }        
        .onAppear {
            selected = sdModels.firstIndex(where: { $0.title == self.modelName }) ?? 0
        }        
    }
}
