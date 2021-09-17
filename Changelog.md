
# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.1] - 2021-09-17

### Changed

- [Issue 10](https://github.com/nashysolutions/Directory/issues/10)
The public init for type `TempPhoto` does not require any params. Params removed. Not considered a breaking change because default values were used and it's unlikely anyone would have passed in a different date value for a photo being captured in the present, for instance.

- [Issue 8](https://github.com/nashysolutions/Directory/issues/8)
The init on type `Photo` is no longer public. Not considered a breaking change because a direct init serves no purpose.

## [2.0.0] - 2021-07-05

Introduces a breaking change.

### Added

- [Issue 2](https://github.com/nashysolutions/Directory/issues/2)
  Added inline documentation.
 
### Changed

- [Issue 1](https://github.com/nashysolutions/Directory/issues/1)
  We now clearly show that we only handle the first item.

```swift
func delete(at index: Int) throws
```
 
### Fixed
 
- [Issue 4](https://github.com/nashysolutions/Directory/issues/4)
  Fixed preview mode.
 
## [1.0.0] - 2021-06-27

Initial Release
