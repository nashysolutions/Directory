
# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [5.0.0] - 2022-07-26

Now supports macOS.

Significant refactoring and the removal of a feature has introduced breaking changes. Have not added deprecations/obsolete message because the changes aren't that impactful really.

### Changed

- [Issue 24](https://github.com/nashysolutions/Directory/issues/24)
Cache now has sensible limit.

### Removed

- [Issue 23](https://github.com/nashysolutions/Directory/issues/23)
Is preview feature removed. Wiki updated.

## [4.0.1] - 2022-07-23

- [Issue 21](https://github.com/nashysolutions/Directory/issues/21)
Updating dependency.

## [4.0.0] - 2021-11-07

Introduces a breaking change. Minimum deployment target set to `iOS 15`.

### Changed

- [Issue 7](https://github.com/nashysolutions/Directory/issues/7)
Adopting the new `Swift 5.5` concurrency features.

## [3.0.0] - 2021-09-21

Introduces a breaking change.

### Changed

- [Issue 13](https://github.com/nashysolutions/Directory/issues/13)
All fetches are async. There is no longer an option to pass in a queue, or choose `.sync`.

### Added

- [Issue 12](https://github.com/nashysolutions/Directory/issues/12)
Images are cached in volatile memory for a short duration of time, to avoid reduce a potentially high frequency of reads from disk, in certain situations.

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
