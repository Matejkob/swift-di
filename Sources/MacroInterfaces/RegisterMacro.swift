/// A macro that registers a dependency in the dependency container.
///
/// The `@Register` macro can only be used on variable declarations inside a `DependencyContainer` extension.
/// It automatically generates the necessary dependency key and accessors for dependency injection.
///
/// # Usage
///
/// ```swift
/// extension DependencyContainer {
///     @Register var myService: MyServiceProtocol = MyService()
/// }
/// ```
///
/// # Requirements
///
/// - The macro must be used inside a `DependencyContainer` extension
/// - Can only be applied to `var` declarations (not `let`)
/// - The property must have a default value
/// - Only one variable can be declared per `@Register` usage
/// - The variable must have a simple identifier pattern
///
/// # Generated Code
///
/// The macro generates:
/// 1. A private dependency key struct with the prefix `__key__`
/// 2. Getter and setter accessors that use the dependency container's subscript
///
/// For example, the above usage generates code equivalent to:
///
/// ```swift
/// private struct __key__myService: DependencyKey {
///     static let defaultValue: MyServiceProtocol = MyService()
/// }
///
/// var myService: MyServiceProtocol {
///     get { self[__key__myService.self] }
///     set { self[__key__myService.self] = newValue }
/// }
/// ```
@attached(accessor)
@attached(peer, names: prefixed(__key__))
public macro Register() =
  #externalMacro(
    module: "MacroImplementations",
    type: "RegisterMacroImplementation"
  )
