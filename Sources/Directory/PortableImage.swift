//
//  PortableImage.swift
//  
//
//  Created by Robert Nash on 25/07/2022.
//

#if canImport(UIKit)
import UIKit
public typealias PortableImage = UIImage
#else
import AppKit
public typealias PortableImage = NSImage
#endif
