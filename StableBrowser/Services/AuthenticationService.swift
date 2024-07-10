import Foundation
import RealmSwift
import LocalAuthentication
import KeychainSwift
import CryptoKit

class AuthenticationService {
    static let shared = AuthenticationService()
    public var isAuthenticated: Bool = false
    
    private let keychain = KeychainSwift()
    private let encryptionKeyKey = "com.stableBrowser.encryptionKey"
    private let passwordKey = "com.stableBrowser.password"
    
    private var encryptionKey: Data?
    
    public func getEncryptionKey() -> Data? {
        return self.encryptionKey
    }

    private init() {
        encryptionKey = loadEncryptionKey()
        if encryptionKey == nil {
            encryptionKey = generateEncryptionKey()
            saveEncryptionKey()
        }
    }
    
    private func generateEncryptionKey() -> Data? {
        let keySize = 32
        var keyData = Data(count: keySize)
        let result = keyData.withUnsafeMutableBytes { mutableBytes -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, keySize, mutableBytes.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            return nil
        }
    }

    
    private func saveEncryptionKey() {
        if let keyData = encryptionKey {
            keychain.set(keyData, forKey: encryptionKeyKey)
        }
    }
    
    private func loadEncryptionKey() -> Data? {
        return keychain.getData(encryptionKeyKey)
    }
    
    func setPassword(_ password: String, usedBiometrics: Bool) {
        let hashedPassword = sha256(password)
        keychain.set(hashedPassword, forKey: passwordKey)
        keychain.set(usedBiometrics, forKey: "usedBiometrics")
        isAuthenticated = true
    }

    func usedBiometricsToSetPassword() -> Bool {
        return keychain.getBool("usedBiometrics") ?? false
    }
    
    func validatePassword(_ password: String) -> Bool {
        let hashedPassword = sha256(password)
        let storedPassword = keychain.get(passwordKey)
        return hashedPassword == storedPassword
    }
    
    func tryLogin(_ password: String, completion: @escaping (Bool) -> Void) {
        isAuthenticated = validatePassword(password)
        completion(isAuthenticated)
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func authenticateUser(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                success, authenticationError in
                DispatchQueue.main.async {
                    completion(success, authenticationError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func authenticateUserWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to set a new password"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                success, authenticationError in
                DispatchQueue.main.async {
                    completion(success, authenticationError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func isBiometricAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func isPasswordSet() -> Bool {
        return keychain.get(passwordKey) != nil
    }
    
    
}
