import ObjectiveC
import KeychainSwift
import RealmSwift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let config = Realm.Configuration(
            schemaVersion: 13,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 13 {
                    migration.enumerateObjects(ofType: StableSettings.className()) { oldObject, newObject in
                        guard let oldObject = oldObject, let newObject = newObject else {
                            print("Warning: Old or new object is nil during migration")
                            return
                        }
                        
                    
                        // Create a new object (initialised with default values)
                        let newSettings = StableSettings()
                        
                        // Copy all properties from newSettings to newObject
                        for property in newSettings.objectSchema.properties {
                            if let value = newSettings.value(forKey: property.name) {
                                newObject[property.name] = value
                            }
                        }
                        
                        // Overwrite with old values where they exist
                        for property in oldObject.objectSchema.properties {
                            if newObject.objectSchema.properties.contains(where: { $0.name == property.name }) {
                                if let value = oldObject.value(forKey: property.name) {
                                    newObject[property.name] = value
                                }
                            } else {
                                print("Warning: Property \(property.name) not found in new schema")
                            }
                        }
                        
                    }
                }
            }
        )
        
        // Set the realm configuration.
        Realm.Configuration.defaultConfiguration = config
        
        // Run the migration manually.
        do {
            _ = try Realm(configuration: config)
        } catch {
            print("Error opening realm: \(error)")            
        }
        
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
