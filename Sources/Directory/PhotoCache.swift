//
//  PhotoCache.swift
//  
//
//  Created by Robert Nash on 23/07/2022.
//

import Cache

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

final class PhotoCache  {
    
    private static let shared = PhotoCache()
    
    private let cache: Cache<PortableImage>
        
    private init() {
        cache = Cache<PortableImage>(maxSize: 50)
    }
    
    static func stash(_ item: PortableImage, for identifier: UUID, duration: Expiry = .short) {
        let cache = PhotoCache.shared.cache
        cache.stash(item, with: identifier, duration: duration)
    }
    
    static func resource(for identifier: UUID) -> PortableImage? {
        let cache = PhotoCache.shared.cache
        return cache.resource(for: identifier)
    }
    
    static func removeResource(for identifier: UUID) {
        let cache = PhotoCache.shared.cache
        cache.removeResource(for: identifier)
    }
}
