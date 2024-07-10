import RealmSwift

class LocalPromptStyle: Object {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var name: String?
    @Persisted var prompt: String?
    @Persisted var negative_prompt: String?
    
    convenience init(id: UUID = UUID(), name: String?, prompt: String?, negative_prompt: String?) {
        self.init()
        self.id = id
        self.name = name
        self.prompt = prompt
        self.negative_prompt = negative_prompt
    }
}
