//
//  TempPhoto.swift
//  
//
//  Created by Robert Nash on 24/07/2022.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Files

public struct TempPhoto: SerializableSovereignContainer, Identifiable, DiskResource {
        
    typealias ResourceType = PortableImage
    
    private enum CodingKeys: String, CodingKey {
        case identifier
    }
    
    public let id: UUID
    public let parent: Folder
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UUID.self, forKey: .identifier)
        self.init(identifier: identifier)
    }
        
    init(identifier: UUID) {
        self.init(identifier: identifier, parent: .temporary)
    }
    
    init(identifier: UUID, parent: Folder) {
        self.id = identifier
        self.parent = parent
    }

    public var folderName: String {
        "Photos"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .identifier)
    }
}
