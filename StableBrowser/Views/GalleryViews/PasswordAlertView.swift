import Foundation
import SwiftUI
struct PasswordAlertView: View {
    @Binding var isShowing: Bool
    var album: Album
    @State private var password: String = ""
    @State private var isPasswordEmpty: Bool = false
    @State private var isPasswordWrong: Bool = false
    
    enum FocusableField {
        case password
    }
    @FocusState var focusField: FocusableField?
    
    var body: some View {
        VStack {
            Spacer()
 
            VStack {
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .focused($focusField, equals: .password)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 7)
                    .onAppear{
                        focusField = .password
                    }
                
                Divider()
                
                HStack {
                    Button(action: {
                        withAnimation{
                            isShowing = false
                        }
                    }, label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.red)
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 20)
                    Spacer()
                    Button(action: {
                        if password.isEmpty {
                            isPasswordEmpty = true
                        } else {
                            PhotoManagementService.shared.tryUnlockAlbum(album: album, password: password) { success in
                                if success {
                                    withAnimation {
                                        isShowing = false
                                        PhotoManagementService.shared.toggleRedrawAlbumList.toggle()
                                    }
                                } else {
                                    isPasswordWrong = true
                                }
                            }
                        }
                    }, label: {
                        Text("OK")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .frame(width: 200, height: 200)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            
            Spacer()
        }
        .onAppear {
            if AuthenticationService.shared.usedBiometricsToSetPassword() {
                AuthenticationService.shared.authenticateUser() { success, error in
                    if success {
                        PhotoManagementService.shared.unlockAlbum(album: album) { success in
                            if success {
                                withAnimation {
                                    isShowing = false
                                    PhotoManagementService.shared.toggleRedrawAlbumList.toggle()
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.clear)
        .alert(isPresented: $isPasswordEmpty, content: {
            Alert(title: Text("Password is Empty"))
        })
        .alert(isPresented: $isPasswordWrong, content: {
            Alert(title: Text("Password is Wrong"))
        })
    }

}
