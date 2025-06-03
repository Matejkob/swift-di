import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DIMacrosCompilerPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    RegisterMacroImplementation.self
  ]
}
