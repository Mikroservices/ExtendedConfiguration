# :ledger: ExtendedConfiguration

![Build Status](https://github.com/Mikroservices/ExtendedConfiguration/workflows/Build/badge.svg)
[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-orange.svg?style=flat)](ttps://developer.apple.com/swift/)
[![Vapor 4](https://img.shields.io/badge/vapor-4.0-blue.svg?style=flat)](https://vapor.codes)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms OS X | Linux](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat)](https://developer.apple.com/swift/)

Library provides mechanism for reading configuration files. 

## Getting started

You need to add library to `Package.swift` file:

 - add package to dependencies:
```swift
.package(url: "https://github.com/Mikroservices/ExtendedConfiguration.git", from: "1.0.0")
```

- and add product to your target:
```swift
.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "ExtendedConfiguration", package: "ExtendedConfiguration")
])
```

Then you can add configuration loading during startup Vapor project:

```swift
try app.settings.load([
    .jsonFile("appsettings.json", optional: false),
    .jsonFile("appsettings.\(self.environment.name).json", optional: true),
    .environmentVariables(.withPrefix("smtp"))
])
```
Each configuration item will override items from previous files. Your `appsettings.json` file can look like on below snippet:

```json
{
    "smtp": {
        "fromName": "Mikroservice",
        "fromEmail": "info@server.com",
        "hostname": "smtp@server.com",
        "port": 465,
        "username": "username",
        "password": "P@ssword",
        "secure": "none"
    }
}
```

Now you can read configuration:

```swift
let variable = request.application.settings.getString(for: "smtp.fromEmail")
```

## Developing

Download the source code and run in command line:

```bash
$ git clone https://github.com/Mikroservices/ExtendedConfiguration.git
$ swift package update
$ swift build
```

Run the following command if you want to open project in Xcode:

```bash
$ open Package.swift
```

## Contributing

You can fork and clone repository. Do your changes and pull a request.
