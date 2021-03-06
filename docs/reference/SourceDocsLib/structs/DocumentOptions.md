**STRUCT**

# `DocumentOptions`

```swift
public struct DocumentOptions
```

> Configuration for DocumentationGenerator
>
> - Parameters:
>   - spmModule: Generate documentation for Swift Package Manager module.
>   - moduleName: Generate documentation for a Swift module.
>   - linkBeginningText: The text to begin links with. Defaults to an empty string.
>   - linkEndingText: The text to end links with. Defaults to '.md'.
>   - inputFolder: Path to the input directory.
>   - outputFolder: Output directory.
>   - minimumAccessLevel: The minimum access level to generate documentation. Defaults to public.
>   - includeModuleNameInPath: Include the module name as part of the output folder path. Defaults to false.
>   - clean: Delete output folder before generating documentation. Defaults to false.
>   - collapsibleBlocks: Put methods, properties and enum cases inside collapsible blocks. Defaults to false.
>   - tableOfContents: Generate a table of contents with properties and methods for each type. Defaults to false.
>   - xcodeArguments: Array of `String` arguments to pass to xcodebuild. Defaults to an empty array.

## Properties
### `spmModule`

```swift
public let spmModule: String?
```

### `moduleName`

```swift
public let moduleName: String?
```

### `linkBeginningText`

```swift
public let linkBeginningText: String
```

### `linkEndingText`

```swift
public let linkEndingText: String
```

### `inputFolder`

```swift
public let inputFolder: String
```

### `outputFolder`

```swift
public let outputFolder: String
```

### `minimumAccessLevel`

```swift
public let minimumAccessLevel: AccessLevel
```

### `includeModuleNameInPath`

```swift
public let includeModuleNameInPath: Bool
```

### `clean`

```swift
public let clean: Bool
```

### `collapsibleBlocks`

```swift
public let collapsibleBlocks: Bool
```

### `tableOfContents`

```swift
public let tableOfContents: Bool
```

### `xcodeArguments`

```swift
public let xcodeArguments: [String]
```

## Methods
### `init(spmModule:moduleName:linkBeginningText:linkEndingText:inputFolder:outputFolder:minimumAccessLevel:includeModuleNameInPath:clean:collapsibleBlocks:tableOfContents:xcodeArguments:)`

```swift
public init(spmModule: String?, moduleName: String?,
            linkBeginningText: String = "", linkEndingText: String = ".md",
            inputFolder: String, outputFolder: String,
            minimumAccessLevel: AccessLevel = .public, includeModuleNameInPath: Bool = false,
            clean: Bool = false, collapsibleBlocks: Bool = false, tableOfContents: Bool = false,
            xcodeArguments: [String] = [])
```
