import Foundation
import XCTest
import Files
@testable import Directory

final class DirectoryTests: XCTestCase {
    
    private var folder: Folder!
    
    override func setUpWithError() throws {
        folder = try Folder.temporary.createSubfolder(named: "DirectoryTests")
    }
    
    override func tearDownWithError() throws {
        try folder.delete()
    }
   
    func testContainer() throws {
        let address = "72 Heol Llinos"
        let property = Property(id: UUID(), date: Date(), address: address, parent: folder)
        XCTAssertEqual(property.folder.parent, property.parent)
        XCTAssertTrue(property.folder.name == address)
    }
    
    func testFileCreated() throws {
        let name = "properties.json"
        _ = try Directory<Property>(parent: folder, fileName: name)
        _ = try folder.file(named: name)
    }
    
    func testDirectoryRead() throws {
        let address = "72 Heol Llinos"
        let property = Property(id: UUID(), date: Date(), address: address, parent: folder)
        let handler = try Directory<Property>(parent: folder, fileName: "properties.data")
        try handler.insert(property)
        try handler.save()
        let fetched = try XCTUnwrap(handler.fetchedItems.first)
        XCTAssertTrue(property == fetched)
    }
    
    func testDirectoryReadPreview() throws {
        let address = "72 Heol Llinos"
        let property = Property(id: UUID(), date: Date(), address: address, parent: folder)
        let handler = try Directory<Property>(parent: folder, fileName: "properties.data", isPreview: true)
        try handler.insert(property)
        try handler.save()
        let fetched = try XCTUnwrap(handler.fetchedItems.first)
        XCTAssertTrue(property == fetched)
    }
    
    func testPhotosFileCreated() throws {
        let address = "72 Heol Llinos"
        let property = Property(id: UUID(), date: Date(), address: address, parent: folder)
        let handler = try PhotosDirectory(item: property)
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cat", withExtension: "png"))
        let data = try Data(contentsOf: url)
        try handler.insert(data)
        try handler.save()
        _ = try property.folder.file(named: "photos.json")
    }
    
    func testPhotoLocation() throws {
        
        let address = "72 Heol Llinos"
        let property = Property(id: UUID(), date: Date(), address: address, parent: folder)
        
        // Photos will be stored within a folder heirarchy, starting at top level 'property.folder'.
        let handler = try PhotosDirectory(item: property)
        
        // Grab the photo
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cat", withExtension: "png"))
        let data = try Data(contentsOf: url)
        
        // Save
        try handler.insert(data)
        
        // Fetch
        let photo = try XCTUnwrap(handler.fetchedItems.first)
        
        // Confirm
        XCTAssertTrue(photo.id.uuidString == photo.fileName)
        let file = try property.folder.subfolder(named: "Photos").file(named: photo.fileName)
        XCTAssertTrue(file.nameExcludingExtension == photo.fileName)
    }
    
    func testTempPhoto() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cat", withExtension: "png"))
        let data = try Data(contentsOf: url)
        let temp = TempPhoto(id: UUID(), date: Date(), folder: folder)
        try temp.write(data)
        XCTAssertTrue(temp.id.uuidString == temp.fileName)
        let file = try folder.subfolder(named: "Photos").file(named: temp.fileName)
        XCTAssertTrue(file.nameExcludingExtension == temp.fileName)
    }
    
    func testMigrateTempPhoto() throws {
        
        let tempName = "Temp"
        
        // make sure subfolder not already present
        XCTAssertThrowsError(try folder.subfolder(named: tempName))
        
        let tempLocation = try folder.createSubfolder(named: tempName)
        
        defer {
            // add teardown block only avail iOS 15
            try! tempLocation.delete()
        }
        
        /// create temp photo
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cat", withExtension: "png"))
        let data = try Data(contentsOf: url)
        let temp = TempPhoto(id: UUID(), date: Date(), folder: tempLocation)
        try temp.write(data)
        
        XCTAssertEqual(temp.parent, tempLocation)
        
        XCTAssertNotNil(temp.read())
        
        /// move temp photo to new location (e.g. a non-temporary location)
        let address = "72 Heol Llinos"
        let property = Property(id: UUID(), date: Date(), address: address, parent: folder)
        let photo = try Photo(temp: temp, item: property)
        
        XCTAssertNotNil(photo.read())
        
        XCTAssertEqual(photo.parent, property.folder)
    }
}

private struct Property: Container {
    
    let id: UUID
    let date: Date
    let address: String
    let parent: Folder
    
    var folderName: String {
        address
    }
}

extension Property: Comparable {
    
    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.date > rhs.date
    }
    
    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id
    }
}

extension Property: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case address, id, date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(String.self, forKey: .address)
        let id = try container.decode(UUID.self, forKey: .id)
        let date = try container.decode(Date.self, forKey: .date)
        let parent = Folder.temporary
        self.init(id: id, date: date, address: address, parent: parent) // never called during testing
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(date, forKey: .date)
        try container.encode(id, forKey: .id)
    }
}
