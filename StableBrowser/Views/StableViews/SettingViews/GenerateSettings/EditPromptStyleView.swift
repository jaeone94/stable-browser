// EditPromptStyleView(mode: .add, viewModel: viewModel, localPromptStyles: $localPromptStyles)

import Foundation
import SwiftUI

struct EditPromptStyleView : View {
    var mode: EditPromptMode
    var viewModel: StableSettingViewModel
    @Binding var localPromptStyles: [LocalPromptStyle]
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var prompt = ""
    @State private var negativePrompt = ""

    var body: some View {
        Form {
            Section {
                // name
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.headline)
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading) {
                    Text("Prompt")
                        .font(.headline)
                    TextEditor(text: $prompt)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                }

                VStack(alignment: .leading) {
                    Text("Negative Prompt")
                        .font(.headline)
                    TextEditor(text: $negativePrompt)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                }
                
            }

            Section {
                Button(action: {
                    switch mode {
                    case .add:
                        viewModel.addPromptStyle(name: name, prompt: prompt, negativePrompt: negativePrompt)
                    case .edit(let promptStyle):
                        viewModel.updatePromptStyle(id: promptStyle.id, name: name, prompt: prompt, negativePrompt: negativePrompt)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Spacer()
                        Text("Save")
                            .foregroundColor(.blue)
                            .font(.headline)
                            .padding()
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            switch mode {
            case .add:
                break
            case .edit(let promptStyle):
                name = promptStyle.name ?? ""
                prompt = promptStyle.prompt ?? ""
                negativePrompt = promptStyle.negative_prompt ?? ""
            }
        }
    }
}
