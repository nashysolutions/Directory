# Directory

A lightweight and thin wrapper that provides a means of accessing the file system in a [SwiftUI](https://developer.apple.com/xcode/swiftui/) environment, conveniently.

### Usage

Let's assume you have a data type called 'Project'.

```swift
struct Project: Identifiable, Equatable, Codable, Container, PhotoStore {
    let name: String
}

struct ContentView: View {
    
    @StateObject var store: Directory<Project>
    
    var body: some View {
        List {
            ForEach(store.fetchedItems) { project in
                NavigationLink(
                    project.name,
                    destination: ProjectView(
                        name: project.name,
                        photos: project.photos
                    )
                )
            }
        }
        .navigationBarItems(trailing: button)
        .onAppear(perform: {
            store.fetch(.async(.global(qos: .userInitiated)))
        })
    }
    
    private var button: some View {
        Button(action: {
            addProject()
        }, label: {
            Image(systemName: "plus")
        })
    }
    
    private func addProject() {
        let project = try! Project(name: "Project " + UUID().uuidString)
        try! store.append(project)
    }
}

struct ProjectView: View {
    
    @State private var isPresented = false
    
    let name: String
    @StateObject var photos: PhotosDirectory<Project>
    
    var body: some View {
        VStack {
            Text(name)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], content: {
                // this loads all the assets, so be memory aware of that.
                ForEach(photos.fetchedItems) { photo in
                    Image(uiImage: photo.read()!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .padding(.vertical)
            })
        }
        .onAppear(perform: {
            // this loads the json, not the assets.
            photos.fetch(.sync)
        })
        .navigationBarItems(trailing: button)
        .sheet(isPresented: $isPresented, content: {
            ImagePicker() { image in
                if let data = image?.pngData() {
                    try! photos.insert(data)
                }
                isPresented = false
            }
        })
    }
    
    private var button: some View {
        Button(action: {
            isPresented = true
        }, label: {
            Text("Button")
        })
    }
}
```

For a detailed implementation, see the [wiki](https://github.com/nashysolutions/Directory/wiki/Home).

Demo App available [here](https://github.com/nashysolutions/Projects).

## Installation

Use the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation). See the [wiki](https://github.com/nashysolutions/Directory/wiki/Home) for more details.
