public protocol DependencyKey {
  associatedtype Value: Sendable
  
  static var defaultValue: Self.Value { get }
}
