
# Homehapp iOS app

---

## Setting up development environment

### Run the following commands:

Install Cocoapods:

```sh
sudo gem install cocoapods
```

Initialize the project dependencies:

```sh
pod install
```
To update Cocoapods dependencies:

```sh
pod update
```

### Open the project

Always open Homehapp.xcworkspace instead of Homehapp.xcodeproj. This
is due to the CocoaPods targets.

## Version control

GIT is used obviously. Use feature branches as well as your own development
branch for smaller increments than a 'feature'. Merge into the main 'develop'
branch ONLY when things WORK, develop should always be in good enough shape
that we can build a release for testing out of it.

Use rebase squash on your private feature branches if you know what
you're doing.

## Project organization

### Images

Use Assets.xcassets for any image assets. No exceptions!

### 3rd party libraries

Use CocoaPods if available. No exceptions! Also make sure the licence does
not cripple our customer's IPR; GPL is not your friend, MIT licence etc. is!

### Data storage

For data storage we're using Realm instead of Core Data. Check it out at
http://realm.io/. Somewhat the same rules apply to data migration as in
Core Data, so BE CAREFUL (and read up on how to do versioning + migration)
when modifying the data model after we've done a first release.

### HTTP

For making HTTP requests we're using the industry standard AlamoFire
library.

## Code style

Follow our coding standard: https://github.com/qvik/swift

## Internalization

To regenerate internalization files, run

```sh
./mergegenstrings.py Homehapp NSLocalizedString en
```

### Release checklist

IMPORTANT: always check these things before making a release of the iOS client:

* Make sure the proper backend URL for production environment is used
* Correct provisioning profile is used (ad-hoc for ad hocs, release for release, etc.)
* Always git tag your releases





