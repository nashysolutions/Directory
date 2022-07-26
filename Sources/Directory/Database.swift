//
//  Database.swift
//  
//
//  Created by Robert Nash on 24/07/2022.
//

import SwiftUI
import Files

public protocol Database: AnyObject {
    associatedtype Item: SerializableSovereignContainer
    var records: [Item] { get set }
    var storage: File { get }
}

public extension Database {
    
    var count: Int {
        records.count
    }
    
    var isEmpty: Bool {
        count == 0
    }
    
    func load() async throws {
        try loadAndWait()
    }
    
    func loadAndWait() throws {
        records = try decode()
    }
    
    private func decode() throws -> [Item] {
        let data = try storage.read()
        if data.isEmpty {
            return []
        }
        return try JSONDecoder().decode([Item].self, from: data)
    }
}

public extension Database {
    
    func delete(at index: Int) throws {
        try removeItem(at: index)
    }
    
    func save() throws {
        let data = try JSONEncoder().encode(records)
        try storage.write(data)
    }
    
    func append(_ candidate: Item) throws {
        if records.contains(candidate) {
            return
        }
        records.append(candidate)
        try save()
    }
    
    func append(_ candidates: [Item]) throws {
        records.append(contentsOf: candidates)
        try save()
    }
    
    func delete(_ candidate: Item) throws {
        if let index = records.firstIndex(of: candidate) {
            try removeItem(at: index)
        }
    }
    
    private func removeItem(at index: Int) throws {
        let item = records.remove(at: index)
        try item.willDiscard()
        try save()
    }
    
    func move(from source: IndexSet, to destination: Int) throws {
        records.move(fromOffsets: source, toOffset: destination)
        try save()
    }
}

public extension Database where Item: Comparable {
    
    func insert(candidates: [Item]) throws {
        var items = records
        items.append(contentsOf: candidates)
        records = items.sorted()
        try save()
    }

    func insert(candidate: Item) throws {
        var items = records
        items.append(candidate)
        records = items.sorted()
        try save()
    }
}
