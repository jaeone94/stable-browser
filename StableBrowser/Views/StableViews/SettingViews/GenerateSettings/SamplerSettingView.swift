//import SwiftUI
//
//struct SamplerSettingView : View {
//    var parent: SamplingOptionsSection
//    var title: String
//    var sampler: String?
//    var key: String
//    @State private var selected = 0
//    @Environment(\.presentationMode) var presentationMode
//    
//    var body: some View {
//        let samplers = parent.viewModel.samplers //  samplers: [String]
//        List {
//            ForEach(0..<samplers.count, id: \.self) { index in
//                Button(action: {
//                    if parent.viewModel.selectedSampler != samplers[index] {
//                        presentationMode.wrappedValue.dismiss()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                            parent.viewModel.setSampler(sampler: samplers[index])
//                        }
//                    }
//                }) {
//                    HStack {
//                        Text(samplers[index])
//                        Spacer()
//                    }
//                    .frame(maxWidth: .infinity) 
//                    .contentShape(Rectangle()) 
//                }
//                .buttonStyle(PlainButtonStyle()) 
//                .foregroundColor(sampler == samplers[index] ? .blue : .primary)
//                .contentShape(Rectangle()) 
//            }
//        }
//    }
//}
