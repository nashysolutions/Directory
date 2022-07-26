import Foundation
import Files

public final class Directory<Item: SerializableSovereignContainer>: ObservableObject, Database {
    
    @Published
    public var records: [Item] = []
        
    public let storage: File
        
    public convenience init(parent: Folder, fileName: String) throws {
        let file = try parent.createFileIfNeeded(withName: fileName)
        self.init(storage: file)
    }
    
    init(storage: File) {
        self.storage = storage
    }
}
