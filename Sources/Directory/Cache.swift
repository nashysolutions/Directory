//
//  ImageCache.swift
//  
//
//  Created by Robert Nash on 23/07/2022.
//

import Cache
import UIKit

final class ImageCache {
    
    private let cache = Cache<UIImage>()
    
    static let shared = ImageCache()
    
    private init() {
        
    }
    
    func stash(_ image: UIImage, for identifier: UUID, duration: Expiry = .short) {
        cache.stash(image, with: identifier, duration: duration)
    }
    
    func resource(for identifier: UUID) -> UIImage? {
        cache.resource(for: identifier)
    }
}
