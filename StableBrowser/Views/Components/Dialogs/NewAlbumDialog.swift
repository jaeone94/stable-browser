import SwiftUI

struct NewAlbumDialog: View {
    @State private var newAlbumName = ""    
    @State private var isSecretNewAlbum: Bool = false
    @State private var password = ""
    @State private var photoManagementService = PhotoManagementService.shared

    @State private var isAlertShown = false
    @State private var alertType: AlertType = .emptyName
    enum AlertType {
        case emptyName
        case emptyPassword
    }
    
    enum FocusableField {
        case name
        case password
    }

    @FocusState var focusField: FocusableField?
    @State private var showPassword: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack{
                Spacer()
                VStack {
                    Text("New Album")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Album Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.leading, 3)
                        
                        TextField("Enter a name for your new album", text: $newAlbumName)
                            .padding()
                            .focused($focusField, equals: .name)
                            .onAppear {
                                focusField = .name
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    Spacer()
                    Toggle(isOn: $isSecretNewAlbum.animation(.easeInOut)) {
                        Text("Secret Album")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.leading, 3)
                    }
                    .padding(.trailing, 5)
                    .padding(.bottom, 10)

                    if isSecretNewAlbum {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.leading, 3)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter a password`", text: $password)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .onChange(of: password) { oldValue, newValue in
                                            // 스페이스를 제거하여 비밀번호를 업데이트합니다.
                                            password = newValue.replacingOccurrences(of: " ", with: "")
                                        }
                                        .frame(height: 40)
                                } else {
                                    SecureField("Enter a password", text: $password)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .onChange(of: password) { oldValue, newValue in
                                            // 스페이스를 제거하여 비밀번호를 업데이트합니다.
                                            password = newValue.replacingOccurrences(of: " ", with: "")
                                        }
                                        .frame(height: 40)
                                        .focused($focusField, equals: .password)
                                        .onAppear {
                                            focusField = .password
                                        }                                        
                                }
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }.padding(.bottom, 10)
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                PhotoManagementService.shared.hideNewAlbumDialog()
                            }
                        }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            createNewAlbum()
                        }) {
                            Text("Confirm")
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                                .background(Color.primary)
                                .foregroundColor(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .frame(width: 350, height: isSecretNewAlbum ? 350: 270)
                .cornerRadius(15)
                .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 2)
                Spacer()
            }
            .background(Color.clear)
            .padding()
            Spacer()
        }
        .onAppear (perform : UIApplication.shared.hideKeyboard)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .alert(isPresented: $isAlertShown) {
            switch alertType {
            case .emptyName:
                return Alert(title: Text("Empty Name"), message: Text("Please enter a name for your new album"), dismissButton: .default(Text("OK")))
            case .emptyPassword:
                return Alert(title: Text("Empty Password"), message: Text("Please enter a password for your new album"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    @MainActor private func createNewAlbum() {
        // Check if the album name is empty (trim)
        if newAlbumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            isAlertShown = true
            alertType = .emptyName
            return
        }
        if isSecretNewAlbum && password.isEmpty {
            isAlertShown = true
            alertType = .emptyPassword
            return
        }
        
        let newAlbum = Album()
        newAlbum.name = newAlbumName
        photoManagementService.addAlbum(name: newAlbumName, isSecret: isSecretNewAlbum, password: password)
        photoManagementService.hideNewAlbumDialog()
    }
    
}
