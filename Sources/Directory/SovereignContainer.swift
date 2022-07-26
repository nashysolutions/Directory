//
//  SovereignContainer.swift
//  
//
//  Created by Robert Nash on 24/07/2022.
//

import Foundation
import Files

public protocol SovereignContainer: DiskLocationAware {
    var folderName: String { get }
    var parent: Folder { get }
}

public extension SovereignContainer {
    
    var folder: Folder {
        try! parent.createSubfolderIfNeeded(withName: folderName)
    }
}
