# Simple Key Value Store in Swift

Create a store:
```swift
let store = try! dbmKeyValueStoreAtURL(databaseURL)
```

Store `NSData` into it:
```swift
store["1"] = "A".dataUsingEncoding(NSUTF8StringEncoding)
store["2"] = "B".dataUsingEncoding(NSUTF8StringEncoding)
```

Read from it:
```swift
let data = store["1"]
```
