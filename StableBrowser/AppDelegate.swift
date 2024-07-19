import ObjectiveC
import KeychainSwift
import RealmSwift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 11, // Must be higher than previous schema version.
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                    // No changes needed but migration to new schema version is required.
                }
            }
        )
        
        StableSettingViewModel.shared.loadCurrentSettings()
        StableSettingViewModel.shared.tryAutoConnectToServer()
        _ = AuthenticationService.shared
        
        // Check if biometrics for setting password is enabled in Keychain.
        let keychain = KeychainSwift()
        if keychain.getBool("usedBiometricsToSetPassword") == nil {
            // If biometrics for setting password is not configured, set default value to false.
            keychain.set(false, forKey: "usedBiometricsToSetPassword")
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        StableSettingViewModel.shared.saveCurrentSettings()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        StableSettingViewModel.shared.saveCurrentSettings()
        CacheManager.shared.clearCache()
    }    
}
