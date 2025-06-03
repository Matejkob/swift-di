/// A key for accessing dependencies in the dependency injection system.
///
/// Types conform to this protocol to define dependencies that can be injected throughout the application.
/// The protocol requires a default value to be provided, which will be used when no other value is explicitly set.
///
/// In most cases, you don't need to manually conform to this protocol. Instead, use the `@Register` macro
/// which automatically generates the necessary conformance and implementation.
///
/// Example usage with `@Register`:
/// ```swift
/// @Register
/// struct UserService {
///     var fetchUser: (String) async throws -> User
///
///     static func defaultValue() -> UserService {
///         UserService(
///             fetchUser: { id in
///                 // Default implementation
///             }
///         )
///     }
/// }
/// ```
///
/// The macro automatically:
/// - Conforms the type to `DependencyKey`
/// - Implements the `defaultValue` property using the static `defaultValue()` method
/// - Registers the dependency in the dependency container
///
/// If you need more control, you can manually conform to the protocol:
/// ```swift
/// struct UserService {
///     var fetchUser: (String) async throws -> User
/// }
///
/// extension UserService: DependencyKey {
///     static var defaultValue: UserService {
///         UserService(
///             fetchUser: { id in
///                 // Default implementation
///             }
///         )
///     }
/// }
/// ```
///
/// The `Value` associated type allows you to specify a different type for the dependency value
/// than the key type itself. By default, it's set to `Self` for convenience.
public protocol DependencyKey {
  /// The type of value that this dependency key provides.
  ///
  /// By default, this is set to `Self`, meaning the key type itself is the value type.
  /// You can override this to provide a different value type if needed.
  associatedtype Value: Sendable = Self

  /// The default value for this dependency.
  ///
  /// This value will be used when no other value is explicitly set for this dependency.
  /// It should provide a sensible default implementation that can be used in production.
  ///
  /// When using the `@Register` macro, this is automatically implemented using the static
  /// `defaultValue()` method of your type.
  static var defaultValue: Self.Value { get }
}
