//
//  PhotoStore.swift
//  
//
//  Created by Robert Nash on 24/07/2022.
//

import Foundation

public protocol PhotoStore: SerializableSovereignContainer {
    var photos: PhotosDirectory<Self> { get }
}
