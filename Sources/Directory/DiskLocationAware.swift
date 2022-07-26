//
//  DiskLocationAware.swift
//  
//
//  Created by Robert Nash on 26/07/2022.
//

import Foundation
import Files

public protocol DiskLocationAware: MemoryConscious {
    var folder: Folder { get }
}
