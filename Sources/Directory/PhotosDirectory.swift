//
//  PhotosDirectory.swift
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

public final class PhotosDirectory<Item: SerializableSovereignContainer>: ObservableObject, Database {
    
    public typealias PhotoItem = Photo<Item>
    
    @Published
    public var records: [PhotoItem] = []
        
    public let storage: File
        
    private let item: Item

    public convenience init(for item: Item) throws {
        let file = try item.folder.createFileIfNeeded(withName: "photos.json")
        self.init(storage: file, item: item)
    }
    
    init(storage: File, item: Item) {
        self.storage = storage
        self.item = item
    }
    
    @discardableResult
    public func append(datas: [Data]) throws -> [PhotoItem] {
        let photos: [PhotoItem] = try datas.map {
            let file = PhotoItem(item: item)
            try file.write($0)
            return file
        }
        try append(photos)
        photos.forEach {
            let image = try! $0.read()!
            PhotoCache.stash(image, for: $0.id)
        }
        return photos
    }
    
    @discardableResult
    public func append(data: Data) throws -> PhotoItem {
        let photo = PhotoItem(item: item)
        try photo.write(data)
        try append(photo)
        let image = try! photo.read()!
        PhotoCache.stash(image, for: photo.id)
        return photo
    }
    
    @discardableResult
    public func append(temps: [TempPhoto]) throws  -> [PhotoItem] {
        let photos: [PhotoItem] = try temps.map {
            try PhotoItem(temp: $0, item: item)
        }
        try append(photos)
        photos.forEach {
            let image = try! $0.read()!
            PhotoCache.stash(image, for: $0.id)
        }
        return photos
    }

    @discardableResult
    public func append(temp: TempPhoto) throws -> PhotoItem {
        let photo = try PhotoItem(temp: temp, item: item)
        try append(photo)
        let image = try! photo.read()!
        PhotoCache.stash(image, for: photo.id)
        return photo
    }
}
