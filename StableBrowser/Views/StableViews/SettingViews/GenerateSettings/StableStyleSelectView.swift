import Foundation
import SwiftUI

enum EditPromptMode {
    case add
    case edit(LocalPromptStyle)
}

enum StyleSelectMode {
    case txt2img
    case img2img
}

struct StableStyleSelectView: View {
    var viewModel: StableSettingViewModel
    var mode: StyleSelectMode
    @Binding var selectedPromptStyles: [String]
    @Binding var localPromptStyles: [LocalPromptStyle]
    @Environment(\.presentationMode) var presentationMode

    @State private var showAlert = false
    @State private var showEditPromptStyle = false
    @State private var editMode: EditPromptMode = .add
    @State private var targetEdit: LocalPromptStyle?
    
    var body: some View {
        Section {
            List {
                ForEach(localPromptStyles, id: \.id) { style in
                    Button(action: {
                        if selectedPromptStyles.contains(style.name ?? "") {
                            selectedPromptStyles.removeAll { $0 == style.name }
                        } else {
                            selectedPromptStyles.append(style.name ?? "")
                        }
                        saveSelectedStyles()
                    }) {
                        HStack {
                            Text(style.name ?? "")
                                .foregroundColor(selectedPromptStyles.contains(style.name ?? "") ? .blue : .primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(action: {
                            viewModel.deletePromptStyle(style.name ?? "")
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .contextMenu {
                        Button(action: {
                            targetEdit = style
                            editMode = .edit(style)
                            showEditPromptStyle = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }.animation(.default, value: localPromptStyles)
            .sheet(isPresented: $showEditPromptStyle) {
                EditPromptStyleView(mode: editMode, viewModel: viewModel, localPromptStyles: $localPromptStyles)
            }
        }

        Section {
            Button(action: {
                showAlert = true
            }) {
                HStack {
                    Spacer()
                    Text("Get Prompt Styles from Web UI Server")
                        .foregroundColor(.blue)
                        .font(.headline)
                        .padding()
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
        }.alert(isPresented: $showAlert) {
            Alert(title: Text("Migration"), message: Text("Do you want to migrate the prompt styles from the web UI server to this app?"), primaryButton: .default(Text("Yes")) {
                viewModel.migratePromptStyles()
            }, secondaryButton: .cancel())
        }
        .navigationBarItems(
            trailing: NavigationLink(destination: EditPromptStyleView(mode: .add, viewModel: viewModel, localPromptStyles: $localPromptStyles)) {
                Image(systemName: "plus.app.fill")
            }
        )
    }
    
    private func saveSelectedStyles() {
        switch mode {
        case .txt2img:
            viewModel.saveTxtSelectedPromptStyles()
        case .img2img:
            viewModel.saveImgSelectedPromptStyles()
        }
    }
}
