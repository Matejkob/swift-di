public struct DependencyContainer: Sendable {
  @TaskLocal static var current: Self = Self()

  private var storage: [ObjectIdentifier: any Sendable] = [:]

  subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
    get {
      if let storedObject = storage[ObjectIdentifier(key)] as? Key.Value {
        return storedObject
      } else {
        return Key.defaultValue
      }
    }

    set {
      storage[ObjectIdentifier(key)] = newValue
    }
  }

  private init() {}
}
