@propertyWrapper public struct Dependency<Value>: Sendable {

  public let keyPath: KeyPath<DependencyContainer, Value> & Sendable

  public var wrappedValue: Value {
    DependencyContainer.current[keyPath: keyPath]
  }

  @inlinable public init(_ keyPath: KeyPath<DependencyContainer, Value> & Sendable) {
    self.keyPath = keyPath
  }
}
