import Foundation
import SwiftUI
import RealmSwift

struct AlbumEditView: View {
    var parent: GalleryView
    @Binding var isShowing: Bool
    @Binding var album: Album?
    @StateObject var photoManagementService = PhotoManagementService.shared
    @State private var albumName: String = ""
    @State private var isSecret: Bool = false
    @State private var showPassword: Bool = false
    @State private var password = ""
    
    @State private var isAlertShown = false
    @State private var alertType: AlertType = .emptyName
    @State private var isSecuredAlbum: Bool = false
    
    enum AlertType {
        case emptyName
        case askDeleteAlbum
        case askDeletePassword
        case duplicateName
    }
    
    var body: some View {
        if let album = album {
            let isLocked = album.isSecret && photoManagementService.unlockedAlbums[album.id] == false
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack {
                            if isLocked {
                                Rectangle()
                                    .fill(Color.gray)
                                    .overlay(
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 50))
                                            .frame(height: 120)
                                            .foregroundColor(.secondary)
                                    )
                                    .frame(height: isSecret ? 80 : 120)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        parent.isShowingPasswordAlert = true
                                    }
                            } else {
                                if let firstPhoto = album.photos.first, let thumbnailData = firstPhoto.getThumbnailData() {
                                    Image(uiImage: UIImage(data: thumbnailData)!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: isSecret ? 80 : 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }else {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .overlay(
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 50))
                                                .frame(height: 120)
                                                .foregroundColor(.secondary)
                                        )
                                        .frame(height: isSecret ? 80 : 120)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                            parent.isShowingPasswordAlert = true
                                        }
                                }
                            }
                        }
                        .frame(height: isSecret ? 80 : 120)
                        .padding(10)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Album Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.leading, 3)
                            
                            TextField("Enter a name", text: $albumName)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            // reset password buton
                            Button(action: {
                                withAnimation {
                                    if isLocked {
                                        parent.isShowingPasswordAlert = true
                                    } else {
                                        isSecret.toggle()
                                    }
                                }
                            }) {
                                if !isSecret {
                                    Text(album.isSecret ? "Reset Password" : "Set Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.accentColor)
                                } else {
                                    Text("Cancel")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        
                        if isSecret {
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
                                                password = newValue.replacingOccurrences(of: " ", with: "")
                                            }
                                            .frame(height: 40)
                                    } else {
                                        SecureField("Enter a password", text: $password)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .onChange(of: password) { oldValue, newValue in
                                                password = newValue.replacingOccurrences(of: " ", with: "")
                                            }
                                            .frame(height: 40)
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
                            Button(action: {
                                withAnimation {
                                    self.isShowing = false
                                    self.isSecret = false
                                }
                            }) {
                                Text("Cancel")
                                    .fontWeight(.medium)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 25)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(action: {
                                alertType = AlertType.askDeleteAlbum
                                isAlertShown = true
                            }) {
                                Text("Delete")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                ModifyingAlbum()
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
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .frame(width: 350, height: isSecret ? 380: 340)
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 2)
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .background(Color.clear)
                .padding(.vertical, 10)
                .padding(.horizontal)
                Spacer()
            }
            .id(album.id)
            .background(Color.clear)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onChange(of: isShowing) { oldValue, newValue in
                isSecret = false
            }
            .onAppear (perform : UIApplication.shared.hideKeyboard)
            .onAppear{
                self.isSecuredAlbum = album.isSecret
                DispatchQueue.main.async {
                    self.albumName = album.name
                }
            }
            .alert(isPresented: $isAlertShown) {
                switch alertType {
                case .emptyName:
                    return Alert(title: Text("Empty Name"), message: Text("Please enter a name for your new album"), dismissButton: .default(Text("OK")))
                case .askDeleteAlbum:
                    return Alert(title: Text("Delete Album"), message: Text("Are you sure you want to delete this album?"), primaryButton: .destructive(Text("Delete"), action: {
                        DeleteAlbum()
                    }), secondaryButton: .cancel())
                case .askDeletePassword:
                    return Alert(title: Text("Delete Password"), message: Text("Are you sure you want to delete the password for this album?"), primaryButton: .destructive(Text("Delete"), action: {
                        photoManagementService.updateAlbum(album: album, name: albumName, isSecret: false, password: nil)
                        withAnimation {
                            isSecret = false
                            isShowing = false
                        }
                    }), secondaryButton: .cancel())
                case .duplicateName:
                    return Alert(title: Text("Duplicate Name"), message: Text("An album with this name already exists. Please choose a different name."), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    private func ModifyingAlbum() {
        if let album = self.album {
            if albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                isAlertShown = true
                alertType = .emptyName
                return
            }
            
            // Check for duplicate album name
            if photoManagementService.albums.contains(where: { $0.id != album.id && $0.name.lowercased() == albumName.lowercased() }) {
                isAlertShown = true
                alertType = .duplicateName
                return
            }
            
            if isSecuredAlbum {
                if isSecret {
                    if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertType = .askDeletePassword
                        withAnimation {
                            isAlertShown = true
                        }
                        return
                    } else {
                        photoManagementService.updateAlbum(album: album, name: albumName, isSecret: true, password: password)
                    }
                } else {
                    photoManagementService.updateAlbum(album: album, name: albumName, isSecret: true, password: nil)
                }
            } else {
                if isSecret {
                    if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        photoManagementService.updateAlbum(album: album, name: albumName, isSecret: false, password: nil)
                    } else {
                        photoManagementService.updateAlbum(album: album, name: albumName, isSecret: true, password: password)
                    }
                }
                else {
                    photoManagementService.updateAlbum(album: album, name: albumName, isSecret: false, password: nil)
                }
            }
            
            withAnimation {
                isSecret = false
                isShowing = false
            }
        }
    }
    
    private func DeleteAlbum() {
        if let album = self.album {
            // Remove from albums first for safe deletion
            photoManagementService.albums.removeAll { $0.id == album.id }
            withAnimation {
                self.album = nil
                self.isShowing = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                photoManagementService.deleteAlbum(Album: album) { success in
                    if success {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}
