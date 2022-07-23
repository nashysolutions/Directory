# Directory

A means of accessing the file system in a [SwiftUI](https://developer.apple.com/xcode/swiftui/) environment, conveniently.

### Usage

Let's assume you have a data type called 'Project'.

```swift
struct Project: Codable, Equatable, Container {

    let name: String
    
    // See wiki/typical-implementation
}
```

By conforming to the above protocols, you may now create `Directory<Project>` or `PhotosDirectory<Project>`.

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
            // store.fetchAndWait()
            Task {
               await store.fetch()
            }
        })
    }
        
    // stores permanently to disk
    // triggers UI re-render
    private func addProject() {
        let project = Project(name: "Project " + UUID().uuidString)
        try! store.append(project)
        // See wiki/useful-api
    }
}
```

Demo App available [here](https://github.com/nashysolutions/Projects).
Only suitable for small payloads. If using larger files and / or CloudKit consider using `NSFilCoordinator` directly.

## Installation

Use the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation). 
