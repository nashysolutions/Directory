# Directory

A means of accessing the file system conveniently.

## Dependencies

Files: https://github.com/JohnSundell/Files

## Usage

```swift

struct Project: Identifiable {
    let id: UUID
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
```
In order for the above to compile you need to extend the type 'Project' to indicate where on disk you would like projects to be saved and in turn where photos for each project should be saved. 

So let's setup a helper first called `FolderStorage`.

```swift
import Files

struct FolderStorage {
    
    static func loadRootFolder() throws -> Folder {
        let folder = try applicationSupportDirectory()
        return try folder.createSubfolderIfNeeded(withName: "Data")
    }
    
    private static func applicationSupportDirectory() throws -> Folder {
        let url = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return try Folder(path: url.path)
    }
}
```

Then let's extend `Project` accordingly.

```swift
import Files
import Directory

struct Project: Identifiable, Container {
    
    let id: UUID
    let name: String
    let parent: Folder
    
    var folderName: String {
        "Project_" + name.alphanumericsOnly
    }
}

private struct Storage {
        
    static func loadProjectFolder() throws -> Folder {
        let folder = try FolderStorage.loadRootFolder()
        return try folder.createSubfolderIfNeeded(withName: "Projects")
    }
}

extension Directory where Item == Project {
    
    // Submit true if this is being used in a `PreviewProvider`.
    convenience init(isPreview: Bool = false) throws {
        let folder = try Storage.loadProjectFolder()
        try self.init(parent: folder, fileName: "projects.json", isPreview: isPreview)
    }
}

extension Project: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        try self.init(id: id, name: name)
    }
    
    // don't encode parent folder
    // setup another init (see the following extension) 
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }
}

extension Project {
    
    init(id: UUID = .init(), name: String) throws {
        let folder = try Storage.loadProjectFolder()
        self.init(id: id, name: name, parent: folder)
    }
}

extension Project: Equatable {
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.name == rhs.name
    }
}

extension Project: PhotoStore {
    
    var photos: PhotosDirectory<Project> {
        try! PhotosDirectory<Project>(item: self)
    }
}

// So now the following directories are setup
//    root: /ApplicationSupportDirectory/Data/
//
//    root/Projects/projects.json
//    root/Projects/Project_name1 <- unique name for each instance of project
//    root/Projects/Project_name2 <- unique name for each instance of project
//
//    root/Projects/Project_nameX/photos.json
//    root/Projects/Project_nameX/photos/photo_1 <- unique name for each instance of Photo
//    root/Projects/Project_nameX/photos/photo_2 <- unique name for each instance of Photo
```
And that's it. Now we can also handle photo storage against individual projects.

```swift
/*
NavigationLink(
    project.name,
    destination: ProjectView(
        name: project.name,
        photos: project.photos
    )
)
*/
struct ProjectView: View {
    
    @State private var isPresented = false
    
    let name: String
    @StateObject var photos: PhotosDirectory<Project>
    
    var body: some View {
        VStack {
            Text(name)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], content: {
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

//   alternatively
//   private var temps: [TempPhoto]

/// temp photos are stored in temp directory
/// so you can ignore them and discard array
/// or...

//    try! photos.insert(temps: temps) // assets now moved to root/Projects/Project_nameX/photos/
```
