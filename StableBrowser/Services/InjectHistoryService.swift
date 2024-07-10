import Foundation
import RealmSwift

class InjectHistoryService: ObservableObject {
    static let shared = InjectHistoryService()
    @Published var injectHistory: [InjectInfo] = []
    @Published var isAutoInjectMode: Bool = false

    init() {
        self.injectHistory = self.loadInjectHistory()
    }

    func loadInjectHistory() -> [InjectInfo] {
        let realm = try! Realm()
        return Array(realm.objects(InjectInfo.self))
    }
    
    func loadInjectHistory(baseUrl: String) -> [InjectInfo] {
        let realm = try! Realm()
        return Array(realm.objects(InjectInfo.self).filter("baseUrl == %@", baseUrl))
    }
    
    func loadInjectHistory(baseUrl: String, src: String) -> InjectInfo? {
        let realm = try! Realm()
        return realm.objects(InjectInfo.self).filter("baseUrl == %@ AND src == %@", baseUrl, src).first
    }

    func addInjectHistory(baseUrl: String, src: String, dest: String) {
        let realm = try! Realm()
        try! realm.write {
            let injectInfo = InjectInfo(baseUrl: baseUrl, src: src, dest: dest)
            realm.add(injectInfo)
            self.injectHistory.append(injectInfo)
        }
    }

    func removeInjectHistory(at indexSet: IndexSet) {
        let realm = try! Realm()
        try! realm.write {
            for index in indexSet {
                realm.delete(self.injectHistory[index])
            }
            self.injectHistory.remove(atOffsets: indexSet)
        }
    }

    func removeAllInjectHistory() {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(self.injectHistory)
            self.injectHistory.removeAll()
        }
    }

    func moveInjectHistory(from source: IndexSet, to destination: Int) {
        let realm = try! Realm()
        try! realm.write {
            self.injectHistory.move(fromOffsets: source, toOffset: destination)
        }
    }

    func updateInjectHistory(src: String, dest: String, at index: Int) {
        let realm = try! Realm()
        try! realm.write {
            self.injectHistory[index].dest = dest
        }
    }
    
    func updateInjectHistory(baseUrl: String, src: String, dest: String) {
        let realm = try! Realm()
        try! realm.write {
            if let injectInfo = realm.objects(InjectInfo.self).filter("baseUrl == %@ AND src == %@", baseUrl, src).first {
                injectInfo.dest = dest
            }
        }
    }


}
