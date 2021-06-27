import UIKit
import SwiftUI
import Files

/// Provides a folder.
public protocol Container {
    var folderName: String { get }
    var parent: Folder { get }
}

public extension Container {
    
    var folder: Folder {
        try! parent.createSubfolderIfNeeded(withName: folderName)
    }
}

/// An item that can bounce on / off disk (read / write)
/// and has a pouch (folder) for storing stuff.
public typealias KangarooItem = Codable & Container

/// A source of model items that are each codable
/// and each have an allocated folder.
public protocol ItemSource: AnyObject {
    associatedtype Item: KangarooItem
    var fetchedItems: [Item] { get set }
}

public extension ItemSource {
    
    var count: Int {
        fetchedItems.count
    }
    
    var isEmpty: Bool {
        count == 0
    }
    
    func move(from source: IndexSet, to destination: Int) {
        fetchedItems.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(source: IndexSet) throws {
        let index = source.first!
        try removeItem(at: index)
    }
    
    func delete(item: Item) throws where Item: Equatable {
        let predicate: (Item) -> Bool = { $0 == item }
        if let index = fetchedItems.firstIndex(where: predicate) {
            try removeItem(at: index)
        }
    }
    
    func removeItem(at index: IndexSet.Element) throws {
        let item = fetchedItems.remove(at: index)
        try item.folder.delete()
    }
    
    func binding(for item: Item) -> Binding<Item> where Item: Equatable {
        let index = fetchedItems.firstIndex(where: { $0 == item } )!
        return Binding(
            get: { self.fetchedItems[index] },
            set: { self.fetchedItems[index] = $0 }
        )
    }
}

public extension ItemSource where Self: ItemStorageLocation {
    
    func move(from source: IndexSet, to destination: Int) throws {
        fetchedItems.move(fromOffsets: source, toOffset: destination)
        try save()
    }
    
    func delete(source: IndexSet) throws {
        let index = source.first!
        try removeItem(at: index)
    }
    
    func delete(item: Item) throws where Item: Equatable {
        let predicate: (Item) -> Bool = { $0 == item }
        if let index = fetchedItems.firstIndex(where: predicate) {
            try removeItem(at: index)
        }
    }
    
    func removeItem(at index: IndexSet.Element) throws {
        let item = fetchedItems.remove(at: index)
        try item.folder.delete()
        try save()
    }
}

public extension ItemSource where Item: Equatable, Self: ItemStorageLocation {
    
    func append(_ candidate: Item) throws {
        if fetchedItems.contains(candidate) {
            return
        }
        fetchedItems.append(candidate)
        try save()
    }
}

public extension ItemSource where Item: Comparable, Self: ItemStorageLocation {
    
    func insert(_ candidates: [Item]) throws {
        var items = fetchedItems
        items.append(contentsOf: candidates)
        fetchedItems = items.sorted()
        try save()
    }
    
    func insert(_ candidate: Item) throws {
        var items = fetchedItems
        items.append(candidate)
        fetchedItems = items.sorted()
        try save()
    }
}

public extension ItemSource where Item == TempPhoto, Self: ItemStorageLocation {
    
    func removeItem(at index: IndexSet.Element) throws {
        let item = fetchedItems.remove(at: index)
        try item.file().delete()
        try save()
    }
}

public enum DispatchOperation {
    case sync, async(DispatchQueue)
}

/// Provides a storage location. Preview mode is suitable for
/// PreviewProviders because it prevents save/write events, meaning
/// all data will remain in memory only.
public protocol ItemStorageLocation: ItemSource {
    var file: File { get }
    var isPreview: Bool { get }
}

public extension ItemStorageLocation {
    
    typealias ErrorConsumer = (Error) -> Void
    
    func fetch(_ operation: DispatchOperation, errorHandler: ErrorConsumer? = nil) {
        switch operation {
        case .sync:
            do {
                fetchedItems = try fetchSynchronously()
            } catch {
                errorHandler?(error)
            }
        case .async(let queue):
            fetchAsynchronously(queue: queue, errorHandler: errorHandler)
        }
    }
    
    private func fetchSynchronously() throws -> [Item] {
        let data = try file.read()
        if data.isEmpty { return [] }
        return try JSONDecoder().decode([Item].self, from: data)
    }
    
    private func fetchAsynchronously(queue: DispatchQueue, errorHandler: ErrorConsumer?) {
        queue.async { [weak self] in
            do {
                if let items = try self?.fetchSynchronously() {
                    DispatchQueue.main.async {
                        self?.fetchedItems = items
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorHandler?(error)
                }
            }
        }
    }
    
    func save() throws {
        if isPreview { return }
        let data = try JSONEncoder().encode(fetchedItems)
        try file.write(data)
    }
}

/// A handler of items that can be persisted, each of which have an
/// allocated folder. The items array is observable.
open class Directory<Item: KangarooItem>: ObservableObject, ItemStorageLocation {
    
    @Published public var fetchedItems: [Item] = []
    
    public let isPreview: Bool
    
    public let file: File
    
    public init(parent: Folder, fileName: String, isPreview: Bool = false) throws {
        self.file = try parent.createFileIfNeeded(withName: fileName)
        self.isPreview = isPreview
    }
}

/// Represents an image that can be stored in a pre-allocated folder.
public protocol Photograph: Identifiable, KangarooItem, Comparable {
    var id: UUID { get }
    var date: Date { get }
}

public extension Photograph {
    
    var fileName: String {
        id.uuidString
    }
    
    func file() throws -> File {
        try folder.file(named: fileName)
    }
    
    func read() -> UIImage? {
        if let data = try? file().read() {
            return UIImage(data: data)
        }
        return nil
    }

    func write(_ data: Data) throws {
        guard !data.isEmpty else {
            try? file().delete()
            return
        }
        let file = try folder.createFileIfNeeded(withName: fileName)
        try file.write(data)
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.date > rhs.date
    }
}

/// Handles the permanent persistence of an image.
public struct Photo<Item: KangarooItem>: Photograph {
    
    private enum CodingKeys: String, CodingKey {
        case id, date, item
    }
    
    public let id: UUID
    public let date: Date
    public let item: Item
    public let parent: Folder
    
    public init(id: UUID = UUID(), date: Date = Date(), item: Item) {
        self.id = id
        self.date = date
        self.item = item
        self.parent = item.folder
    }
    
    public init(temp: TempPhoto, item: Item) throws {
        let file = try temp.file()
        self.init(id: temp.id, date: temp.date, item: item)
        try file.move(to: folder)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let date = try container.decode(Date.self, forKey: .date)
        let item = try container.decode(Item.self, forKey: .item)
        self.init(id: id, date: date, item: item)
    }
    
    public var folderName: String {
        "Photos"
    }
}

/// Handles the temporary persistence of an image. The image
/// is stored in the temp directory.
public struct TempPhoto: Photograph {
    
    private enum CodingKeys: String, CodingKey {
        case id, date
    }
    
    public let id: UUID
    public let date: Date
    public let parent: Folder
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let date = try container.decode(Date.self, forKey: .date)
        self.init(id: id, date: date)
    }
    
    public init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
        self.parent = .temporary
    }
    
    init(id: UUID, date: Date, folder: Folder) {
        self.id = id
        self.date = date
        self.parent = folder
    }
        
    public var folderName: String {
        "Photos"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
    }
}
/// A handler of photos that can be persisted, each of which have an
/// allocated folder. The items array is observable.
public final class PhotosDirectory<Item: KangarooItem>: Directory<Photo<Item>> {
    
    private let item: Item
    
    public init(item: Item, isPreview: Bool = false) throws {
        self.item = item
        try super.init(parent: item.folder, fileName: "photos.json", isPreview: isPreview)
    }
    
    public func readFirst() -> UIImage? {
        fetchedItems.first?.read()
    }
    
    public func insert(_ datas: [Data]) throws {
        let photos: [Photo<Item>] = try datas.map {
            let file = Photo(item: item)
            try file.write($0)
            return file
        }
        try insert(photos)
    }
    
    public func insert(_ data: Data) throws {
        let photo = Photo(item: item)
        try photo.write(data)
        try insert(photo)
    }
    
    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// Order is maintained.
    /// - Parameter temps: The assets currently stored in the temp directory.
    /// - Throws: LocationError
    public func insert(temps: [TempPhoto]) throws {
        let photos: [Photo] = try temps.map {
            try Photo(temp: $0, item: item)
        }
        try insert(photos)
    }

    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// Order is maintained.
    /// - Parameter temp: The asset currently stored in the temp directory.
    /// - Throws: LocationError
    public func insert(temp: TempPhoto) throws {
        let photo = try Photo(temp: temp, item: item)
        try insert(photo)
    }
    
    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// - Parameter temp: The asset currently stored in the temp directory.
    /// - Throws: LocationError
    public func append(temp: TempPhoto) throws {
        let photo = try Photo(temp: temp, item: item)
        try append(photo)
    }
    
    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// - Parameter temps: The assets currently stored in the temp directory.
    /// - Throws: LocationError
    public func append(temps: [TempPhoto]) throws {
        let photos: [Photo] = try temps.map {
            try Photo(temp: $0, item: item)
        }
        fetchedItems.append(contentsOf: photos)
        try save()
    }
}

public protocol PhotoStore: KangarooItem {
    var photos: PhotosDirectory<Self> { get }
}
