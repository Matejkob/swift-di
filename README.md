# Swift DI

A modern, lightweight dependency injection framework for Swift, leveraging Swift macros for compile-time safety and performance.

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2013+%20|%20macOS%2010.15+%20|%20tvOS%2013+%20|%20watchOS%206+-blue.svg)](https://swift.org)

## Features

- 🏗️ **Macro-driven**: Use `@Register` for clean, compile-time dependency registration
- 📱 **Multi-platform**: Supports iOS, macOS, tvOS, watchOS, and Mac Catalyst
- 🔒 **Sendable**: Full Swift concurrency support with `@TaskLocal` scoping
- ⚡ **Performance**: Zero-runtime overhead with compile-time code generation
- 🎯 **Type-safe**: Full type safety with Swift's type system
- 🧹 **Clean API**: Minimal boilerplate with intuitive property wrapper syntax

## Quick Start

### Installation

Add Swift DI to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/Matejkob/swift-di.git", from: "1.0.0")
]
```

### Basic Usage

1. **Define your services**:

```swift
protocol NetworkService {
    func fetchData() async throws -> Data
}

struct APIService: NetworkService {
    func fetchData() async throws -> Data {
        // Implementation here
    }
}
```

2. **Register dependencies**:

```swift
import DI
import DIMacros

extension DependencyContainer {
    @Register var networkService: NetworkService = APIService()
    @Register var apiKey: String = "default-api-key"
}
```

3. **Inject dependencies**:

```swift
struct UserRepository {
    @Dependency(\.networkService) var networkService
    @Dependency(\.apiKey) var apiKey
    
    func fetchUser(id: String) async throws -> User {
        // Use injected dependencies
        let data = try await networkService.fetchData()
        // Process data...
    }
}
```

## Advanced Usage

### Protocol-based Dependencies

```swift
protocol UserRepository {
    func fetchUser(id: String) async throws -> User
}

struct RemoteUserRepository: UserRepository {
    @Dependency(\.networkService) var networkService
    
    func fetchUser(id: String) async throws -> User {
        // Remote implementation
    }
}

struct LocalUserRepository: UserRepository {
    func fetchUser(id: String) async throws -> User {
        // Local implementation
    }
}

extension DependencyContainer {
    @Register var userRepository: UserRepository = RemoteUserRepository()
}
```

### Configuration Dependencies

```swift
struct AppConfiguration {
    let baseURL: URL
    let timeout: TimeInterval
    let retryCount: Int
}

extension DependencyContainer {
    @Register var config: AppConfiguration = AppConfiguration(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 30.0,
        retryCount: 3
    )
}
```

### Testing with Dependency Injection

```swift
import XCTest
@testable import YourApp

class UserRepositoryTests: XCTestCase {
    func testFetchUser() async throws {
        // Override dependencies for testing
        await DependencyContainer.$current.withValue(DependencyContainer()) {
            DependencyContainer.current[\.networkService] = MockNetworkService()
            
            let repository = UserRepository()
            let user = try await repository.fetchUser(id: "123")
            
            XCTAssertEqual(user.id, "123")
        }
    }
}

struct MockNetworkService: NetworkService {
    func fetchData() async throws -> Data {
        // Mock implementation
        return Data()
    }
}
```

### SwiftUI Integration

```swift
import SwiftUI

struct ContentView: View {
    @Dependency(\.userRepository) var userRepository
    @State private var user: User?
    
    var body: some View {
        VStack {
            if let user = user {
                Text("Hello, \(user.name)!")
            } else {
                Text("Loading...")
            }
        }
        .task {
            do {
                user = try await userRepository.fetchUser(id: "current")
            } catch {
                print("Failed to fetch user: \(error)")
            }
        }
    }
}
```

## Architecture

Swift DI consists of three main components:

### 1. DependencyKey Protocol

Defines the contract for dependency keys:

```swift
protocol DependencyKey {
    associatedtype Value: Sendable = Self
    static var defaultValue: Self.Value { get }
}
```

### 2. DependencyContainer

Thread-safe container using `@TaskLocal` for scoped access:

```swift
@TaskLocal static var current: DependencyContainer
```

### 3. @Register Macro

Compile-time code generation for dependency registration:

```swift
// This code:
@Register var service: MyService = MyService()

// Generates:
private struct __key__service: DependencyKey {
    static let defaultValue: MyService = MyService()
}

var service: MyService {
    get { self[__key__service.self] }
    set { self[__key__service.self] = newValue }
}
```

## Requirements

- Swift 6.1+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Swift DI is available under the MIT license. See the LICENSE file for more info.