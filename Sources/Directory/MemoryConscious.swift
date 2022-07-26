//
//  MemoryConscious.swift
//  
//
//  Created by Robert Nash on 25/07/2022.
//

import Foundation

public protocol MemoryConscious {
}

extension MemoryConscious where Self: DiskLocationAware {
    
    func willDiscard() throws {
        try folder.delete()
    }
}
