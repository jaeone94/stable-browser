import SwiftUI

struct SDVAESettingView: View {
    var parent: StableSettingsView
    var title: String
    var modelName: String
    
    var body: some View {
        let sdVaes = parent.stableSettingViewModel.sdVAEs
        List {
            Button(action: {
                parent.stableSettingViewModel.setSDVAE(model: "Automatic")
            }) {
                HStack {
                    Text("Automatic")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundColor(modelName == "Automatic" ? .blue : .primary)
            .contentShape(Rectangle())
            .onTapGesture {
                if modelName != "Automatic" {
                    parent.stableSettingViewModel.setSDVAE(model: "Automatic")
                }
            }
            
            ForEach(0..<sdVaes.count, id: \.self) { index in
                Button(action: {
                    parent.stableSettingViewModel.setSDVAE(model: sdVaes[index])
                }) {
                    HStack {
                        Text(sdVaes[index])
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundColor(modelName == sdVaes[index] ? .blue : .primary)
                .contentShape(Rectangle())
                .onTapGesture {
                    if modelName != sdVaes[index] {
                        parent.stableSettingViewModel.setSDVAE(model: sdVaes[index])
                    }
                }
            }
        }        
    }
}
