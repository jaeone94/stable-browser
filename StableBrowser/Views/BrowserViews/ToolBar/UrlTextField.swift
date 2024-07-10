import SwiftUI
import UIKit

struct UrlTextField: UIViewRepresentable {
    // MARK: - Properties
    var parent: BrowserView
    @Binding var text: String
    var onCommit: () -> Void

    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        configureTextField(textField)
        textField.delegate = context.coordinator // Set delegate to coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidEndEditing(_:)), for: .editingDidEndOnExit)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal) // Set low content compression resistance priority for horizontal axis
        textField.attributedPlaceholder = NSAttributedString(string: "Enter URL", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        let interaction = UIEditMenuInteraction(delegate: context.coordinator)
        uiView.addInteraction(interaction)
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Methods
    private func configureTextField(_ textField: UITextField) {
        textField.textAlignment = .left
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
    }
}

// MARK: - Coordinator
extension UrlTextField {
    class Coordinator: NSObject, UITextFieldDelegate, UIEditMenuInteractionDelegate {
        var parent: UrlTextField

        init(_ textField: UrlTextField) {
            self.parent = textField
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
        }

        @objc func textFieldDidEndEditing(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.onCommit()
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let startPosition = textField.position(from: textField.beginningOfDocument, offset: 0) {
                    textField.selectedTextRange = textField.textRange(from: startPosition, to: startPosition)
                    textField.selectAll(nil)
                }
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            parent.parent.hideUrlEditView()
        }
        
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let copyAction = UIAction(title: "Copy") { _ in
                UIPasteboard.general.string = self.parent.text
            }
            
            let pasteAction = UIAction(title: "Paste") { _ in
                if let string = UIPasteboard.general.string {
                    self.parent.text = string
                }
            }
            
            return UIMenu(title: "", children: [copyAction, pasteAction])
        }
    }
}
