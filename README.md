# Directory

A means of accessing the file system in a [SwiftUI](https://developer.apple.com/xcode/swiftui/) environment, conveniently. Only suitable for small payloads. If using larger files and / or CloudKit consider using `NSFilCoordinator` directly.

### Usage

Let's assume you have a data type called 'Project'.

```swift
struct Project: Codable {
    let name: String
}
```

Using this package, you could setup a `@StateObject` of type `Directory<Project>` which will store that type to disk. You may also want to save images using `PhotosDirectory<Project>`.

```swift
struct ContentView: View {
    
    @StateObject var store: Directory<Project>
    
    var body: some View {
        List {
            ForEach(store.fetchedItems) { project in
                // do something
            }
        }
        .onAppear(perform: {
            store.fetch()
        })
    }
        
    // stores permanently to disk
    // triggers UI re-render
    private func addProject() {
        let project = Project(name: "Project " + UUID().uuidString)
        try! store.append(project)
    }
}
```

For the above to compile, the type `Project` would need to conform to a few protocols. For a detailed implementation, see the [wiki](https://github.com/nashysolutions/Directory/wiki/Home).

Demo App available [here](https://github.com/nashysolutions/Projects).

## Installation

Use the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation). 
See the [wiki](https://github.com/nashysolutions/Directory/wiki/Home) for more details.
