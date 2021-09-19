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
    
    private func read() throws -> [Item] {
        let data = try file.read()
        if data.isEmpty { return [] }
        return try JSONDecoder().decode([Item].self, from: data)
    }
    
    /// Asynchronously fetch data from disk.
    /// - Parameter errorHandler: Fired if a `DecodingError` is thrown.
    func fetch(errorHandler: ErrorConsumer? = nil) {
        if isPreview { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                if let items = try self?.read() {
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
    
    func move(from source: IndexSet, to destination: Int) throws {
        fetchedItems.move(fromOffsets: source, toOffset: destination)
        try save()
    }
    
    func delete(at index: Int) throws {
        try removeItem(at: index)
    }
    
    private func removeItem(at index: Int) throws {
        let item = fetchedItems.remove(at: index)
        try item.folder.delete()
        try save()
    }
    
    func save() throws {
        if isPreview { return }
        let data = try JSONEncoder().encode(fetchedItems)
        try file.write(data)
    }
}

public extension ItemStorageLocation where Item: Equatable {
    
    /// Append an item to the end of the collection of existing items.
    /// If the item already exists, it will be ignored. A save event
    /// occurs automatically.
    /// - Parameter candidate: The item to append.
    /// - Throws: WriteError, EncodingError
    func append(_ candidate: Item) throws {
        if fetchedItems.contains(candidate) {
            return
        }
        fetchedItems.append(candidate)
        try save()
    }
    
    /// Delete the specified item. If the item does not exist,
    /// then it is ignored.
    /// - Parameter item: The item to delete.
    /// - Throws: LocationError, StoreError
    func delete(item: Item) throws {
        if let index = fetchedItems.firstIndex(of: item) {
            try removeItem(at: index)
        }
    }
    
    /// Establish a binding to the specified item.
    /// - Parameter item: The item to bind. Must be present in the store.
    /// - Returns: A binding.
    func binding(for item: Item) -> Binding<Item> {
        let index = fetchedItems.firstIndex(of: item)!
        return Binding(
            get: { self.fetchedItems[index] },
            set: { self.fetchedItems[index] = $0 }
        )
    }
}

public extension ItemStorageLocation where Item: Comparable {
    
    /// Inserts an item into the collection of existing items, in
    /// chronological order. A save event occurs automatically.
    /// - Parameter candidates: The items to insert.
    /// - Throws: WriteError
    func insert(_ candidates: [Item]) throws {
        var items = fetchedItems
        items.append(contentsOf: candidates)
        fetchedItems = items.sorted()
        try save()
    }
    
    /// Inserts an item into the collection of existing items, in
    /// chronological order. A save event occurs automatically.
    /// - Parameter candidate: The item to insert.
    /// - Throws: WriteError
    func insert(_ candidate: Item) throws {
        var items = fetchedItems
        items.append(candidate)
        fetchedItems = items.sorted()
        try save()
    }
}

public extension ItemStorageLocation where Item == TempPhoto {
    
    func removeItem(at index: Int) throws {
        let item = fetchedItems.remove(at: index)
        try item.file().delete()
        try save()
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
    
    init(id: UUID = UUID(), date: Date = Date(), item: Item) {
        self.id = id
        self.date = date
        self.item = item
        self.parent = item.folder
    }
    
    init(temp: TempPhoto, item: Item) throws {
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
    
    public init() {
        self.init(id: .init(), date: .init())
    }
    
    private init(id: UUID, date: Date) {
        self.init(id: id, date: date, folder: .temporary)
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
    
    /// Create items and inserts them into the collection of existing items. The
    /// order of which, as specified in your implementation of `Comparable`
    /// will be maintained. A save event occurs automatically.
    /// - Parameter datas: The photo data to insert.
    public func insert(_ datas: [Data]) throws {
        let photos: [Photo<Item>] = try datas.map {
            let file = Photo(item: item)
            try file.write($0)
            return file
        }
        try insert(photos)
    }
    
    /// Creates an item and inserts it into the collection of existing items. The
    /// order of which, as specified in your implementation of `Comparable`
    /// will be maintained. A save event occurs automatically.
    /// - Parameter data: The photo data to insert.
    /// - Throws: WriteError
    public func insert(_ data: Data) throws {
        let photo = Photo(item: item)
        try photo.write(data)
        try insert(photo)
    }
    
    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// Order is maintained. A save event occurs automatically.
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
    /// Order is maintained. A save event occurs automatically.
    /// - Parameter temp: The asset currently stored in the temp directory.
    /// - Throws: LocationError
    public func insert(temp: TempPhoto) throws {
        let photo = try Photo(temp: temp, item: item)
        try insert(photo)
    }
    
    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// A save event occurs automatically.
    /// - Parameter temp: The asset currently stored in the temp directory.
    /// - Throws: LocationError
    public func append(temp: TempPhoto) throws {
        let photo = try Photo(temp: temp, item: item)
        try append(photo)
    }
    
    /// Converts a temp photo into a permanent photo by moving
    /// the location of the asset out of a temp directory to a (presumably)
    /// non-temp directory (as specified in your Item's container implementation).
    /// A save event occurs automatically.
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
