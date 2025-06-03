import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that registers a dependency in the dependency container.
/// The macro can only be used on variable declarations inside a DependencyContainer extension.
///
/// Example usage:
/// ```swift
/// extension DependencyContainer {
///     @Register var myService: MyServiceProtocol = MyService()
/// }
/// ```
public enum RegisterMacroImplementation: AccessorMacro, PeerMacro {
  private static let macroName = "@Register"
  private static let keyPrefix = "__key__"
  private static let dependencyKeyVariableName = "defaultValue"
  private static let dependencyKeyProtocolName = "DependencyKey"
  private static let dependencyContainerName = "DependencyContainer"

  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    // Note: The commented out code below would check if the macro is used within a DependencyContainer extension
    // Example of invalid usage (not in DependencyContainer extension):
    // ```swift
    // struct MyStruct {
    //     @Register var myService: MyService = MyService() // Error: @Register macro can only be used inside DependencyContainer extension
    // }
    // ```
    //    #if canImport(SwiftSyntax600)
    //    guard let contextNode = context.lexicalContext.first(where: { $0.is(ExtensionDeclSyntax.self) }),
    //          let extensionDeclSyntax = contextNode.as(ExtensionDeclSyntax.self),
    //          let extendedType = extensionDeclSyntax.extendedType.as(IdentifierTypeSyntax.self),
    //          extendedType.name.text == dependencyContainerName else {
    //      context.diagnose(
    //        Diagnostic(
    //          node: declaration,
    //          message: SimpleDiagnosticMessage(
    //            message: "\(macroName) macro can only be attached to var declarations inside extensions of `DependencyContainer`",
    //            severity: .error
    //          )
    //        )
    //      )
    //      return []
    //    }
    //    #endif

    // Validates that the declaration is a variable declaration
    // Example of invalid usage (not a variable declaration):
    // ```swift
    // extension DependencyContainer {
    //     @Register func myFunction() {} // Error: @Register macro can only be attached to property declarations
    // }
    // ```
    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      context.diagnose(
        Diagnostic(
          node: declaration,
          message: SimpleDiagnosticMessage(
            message: "\(macroName) macro can only be attached to property declarations",
            severity: .error
          )
        )
      )
      return []
    }

    // Validates that the declaration uses 'var' instead of 'let'
    // Example of invalid usage (using let instead of var):
    // ```swift
    // extension DependencyContainer {
    //     @Register let myService: MyService = MyService() // Error: @Register can only be applied to a 'var' declaration
    // }
    // ```
    guard variableDecl.bindingSpecifier.text == TokenSyntax.keyword(.var).text else {
      context.diagnose(
        Diagnostic(
          node: variableDecl.bindingSpecifier,
          message: SimpleDiagnosticMessage(
            message: "\(macroName) can only be applied to a 'var' declaration",
            severity: .error
          ),
          fixIts: [
            FixIt(
              message: SimpleFixItMessage(message: "Replace 'let' with 'var'"),
              changes: [
                .replace(
                  oldNode: Syntax(variableDecl.bindingSpecifier),
                  newNode: Syntax(TokenSyntax.keyword(.var))
                )
              ]
            )
          ]
        )
      )
      return []
    }

    // Validates that there is exactly one binding in the variable declaration
    // Example of invalid usage (multiple bindings):
    // ```swift
    // extension DependencyContainer {
    //     @Register var service1 = Service1(), service2 = Service2() // Error: @Register can only be applied to a single variable declaration
    // }
    // ```
    guard let binding = variableDecl.bindings.first else {
      context.diagnose(
        Diagnostic(
          node: variableDecl,
          message: SimpleDiagnosticMessage(
            message: "\(macroName) can only be applied to a single variable declaration",
            severity: .error
          )
        )
      )
      return []
    }

    // Validates that the binding has a simple identifier pattern
    // Example of invalid usage (complex pattern):
    // ```swift
    // extension DependencyContainer {
    //     @Register var (service1, service2) = (Service1(), Service2()) // Error: @Register can only be applied to a single variable with one identifier
    // }
    // ```
    guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
      context.diagnose(
        Diagnostic(
          node: binding.pattern,
          message: SimpleDiagnosticMessage(
            message: "\(macroName) can only be applied to a single variable with one identifier",
            severity: .error
          )
        )
      )
      return []
    }

    let keyName = keyPrefix + identifier.text

    return [
      AccessorDeclSyntax(
        accessorSpecifier: .keyword(.get),
        body: CodeBlockSyntax {
          "self[\(raw: keyName).self]"
        }
      ),
      AccessorDeclSyntax(
        accessorSpecifier: .keyword(.set),
        body: CodeBlockSyntax {
          "self[\(raw: keyName).self] = newValue"
        }
      ),
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let variableDecl = declaration.as(VariableDeclSyntax.self),
      let binding = variableDecl.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
    else {
      // There is no need to add daiagnostic here since the expanstion of an accessor macro will
      // cover all diagnostic to this point
      return []
    }

    // Validates that the variable has an initializer value
    // Example of invalid usage (no default value):
    // ```swift
    // extension DependencyContainer {
    //     @Register var myService: MyService // Error: Property must have a default value when using @Register macro
    // }
    // ```
    guard let variableValue = binding.initializer?.value.trimmed else {
      context.diagnose(
        Diagnostic(
          node: binding,
          message: SimpleDiagnosticMessage(
            message: "Property must have a default value when using \(macroName) macro",
            severity: .error
          )
        )
      )
      return []
    }

    let keyName = keyPrefix + identifier.text

    if let variableType = binding.typeAnnotation?.type.trimmed {
      return [
        DeclSyntax(
          """
          private struct \(raw: keyName): \(raw: dependencyKeyProtocolName) {
            static let \(raw: dependencyKeyVariableName): \(variableType) = \(variableValue)
          }
          """
        )
      ]
    } else {
      return [
        DeclSyntax(
          """
          private struct \(raw: keyName): \(raw: dependencyKeyProtocolName) {
            static let \(raw: dependencyKeyVariableName) = \(variableValue)
          }
          """
        )
      ]
    }
  }
}

private struct SimpleDiagnosticMessage: DiagnosticMessage {
  let message: String
  let diagnosticID: MessageID = MessageID(domain: "swift-di", id: "RegisterMacro")
  let severity: DiagnosticSeverity
}

private struct SimpleFixItMessage: FixItMessage {
  let message: String
  let fixItID: MessageID = MessageID(domain: "swift-di", id: "RegisterMacroFixIt")
}
