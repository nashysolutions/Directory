//
//  DiskResource.swift
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

public protocol DiskResource: DiskLocationAware, Identifiable {
    var fileName: String { get }
    func read() throws -> PortableImage?
    func write(_ data: Data) throws
}

public extension DiskResource where Self.ID == UUID {
    
    var fileName: String {
        id.uuidString
    }
    
    func file() throws -> File {
        try folder.file(named: fileName)
    }
    
    func read() throws -> PortableImage? {
        if let resource = PhotoCache.resource(for: id) {
            return resource
        }
        
        let data = try file().read()
        guard let image = PortableImage(data: data) else {
            return nil
        }
        
        PhotoCache.stash(image, for: id)
        return image
    }
    
    
    func write(_ data: Data) throws {
        if data.isEmpty {
            throw PhotoError.invalidData
        }
        guard let image = PortableImage(data: data) else {
            throw PhotoError.invalidData
        }
        let file = try folder.createFileIfNeeded(withName: fileName)
        try file.write(data)
        PhotoCache.stash(image, for: id)
    }
}
