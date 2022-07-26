//
//  Photo.swift
//  
//
//  Created by Robert Nash on 24/07/2022.
//

import Files
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public struct Photo<Item: SerializableContainer>: SerializableSovereignContainer, Identifiable, DiskResource {
    
    typealias ResourceType = PortableImage

    private enum CodingKeys: String, CodingKey {
        case identifier, item
    }
    
    public let id: UUID
    public let parent: Folder
    let item: Item
    
    init(item: Item) {
        self.init(identifier: .init(), item: item)
    }
    
    init(identifier: UUID, item: Item) {
        self.id = identifier
        self.item = item
        self.parent = item.folder
    }
    
    init(temp: TempPhoto, item: Item) throws {
        let file = try temp.file()
        self.init(identifier: temp.id, item: item)
        try file.move(to: folder)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UUID.self, forKey: .identifier)
        let item = try container.decode(Item.self, forKey: .item)
        self.init(identifier: identifier, item: item)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .identifier)
        try container.encode(item, forKey: .item)
    }
    
    public var folderName: String {
        "Photos"
    }
}
