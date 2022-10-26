import CIndexStore

public struct SymbolRoles: OptionSet {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

#if os(macOS)
    init(_ value: indexstore_symbol_role_t) {
        self.init(rawValue: value.rawValue)
    }

    public static let declaration = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_DECLARATION)
    public static let definition = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_DEFINITION)
    public static let reference = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REFERENCE)
    public static let read = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_READ)
    public static let write = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_WRITE)
    public static let call = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_CALL)
    public static let dynamic = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_DYNAMIC)
    public static let addressOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_ADDRESSOF)
    public static let implicit = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_IMPLICIT)
    public static let undefinition = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_UNDEFINITION)
    public static let nameReference = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_NAMEREFERENCE)

    // Relation roles.
    public static let childOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_CHILDOF)
    public static let baseOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_BASEOF)
    public static let overrideOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_OVERRIDEOF)
    public static let receivedBy = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_RECEIVEDBY)
    public static let calledBy = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_CALLEDBY)
    public static let extendedBy = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_EXTENDEDBY)
    public static let accessorOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_ACCESSOROF)
    public static let containedBy = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_CONTAINEDBY)
    public static let IBTypeOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_IBTYPEOF)
    public static let specializationOf = SymbolRoles(.INDEXSTORE_SYMBOL_ROLE_REL_SPECIALIZATIONOF)
#elseif os(Linux)
    init(_ value: Int) {
        self.init(rawValue: UInt64(value))
    }

    init(_ value: UInt64) {
        self.init(rawValue: value)
    }

    public static let declaration = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_DECLARATION)
    public static let definition = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_DEFINITION)
    public static let reference = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REFERENCE)
    public static let read = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_READ)
    public static let write = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_WRITE)
    public static let call = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_CALL)
    public static let dynamic = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_DYNAMIC)
    public static let addressOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_ADDRESSOF)
    public static let implicit = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_IMPLICIT)
    public static let undefinition = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_UNDEFINITION)
    public static let nameReference = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_NAMEREFERENCE)

    // Relation roles.
    public static let childOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_CHILDOF)
    public static let baseOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_BASEOF)
    public static let overrideOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_OVERRIDEOF)
    public static let receivedBy = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_RECEIVEDBY)
    public static let calledBy = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_CALLEDBY)
    public static let extendedBy = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_EXTENDEDBY)
    public static let accessorOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_ACCESSOROF)
    public static let containedBy = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_CONTAINEDBY)
    public static let IBTypeOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_IBTYPEOF)
    public static let specializationOf = SymbolRoles(INDEXSTORE_SYMBOL_ROLE_REL_SPECIALIZATIONOF)
#endif
}

public extension SymbolRoles {
    static let relationRoles: SymbolRoles = [
        .childOf,
        .baseOf,
        .overrideOf,
        .receivedBy,
        .calledBy,
        .extendedBy,
        .accessorOf,
        .containedBy,
        .IBTypeOf,
        .specializationOf,
    ]
}

extension SymbolRoles: CaseIterable {
    public static var allCases: [SymbolRoles] {
        return [
            .declaration,
            .definition,
            .reference,
            .read,
            .write,
            .call,
            .dynamic,
            .addressOf,
            .implicit,
            .childOf,
            .baseOf,
            .overrideOf,
            .receivedBy,
            .calledBy,
            .extendedBy,
            .accessorOf,
            .containedBy,
            .IBTypeOf,
            .specializationOf,
        ]
    }
}

extension SymbolRoles: CustomStringConvertible {
    public var description: String {
        var names: [String] = []
        for role in Self.allCases where self.contains(role) {
            switch role {
            case .declaration: names.append("declaration")
            case .definition: names.append("definition")
            case .reference: names.append("reference")
            case .read: names.append("read")
            case .write: names.append("write")
            case .call: names.append("call")
            case .dynamic: names.append("dynamic")
            case .addressOf: names.append("addressOf")
            case .implicit: names.append("implicit")
            case .undefinition: names.append("undefinition")
            case .nameReference: names.append("nameReference")
            case .childOf: names.append("childOf")
            case .baseOf: names.append("baseOf")
            case .overrideOf: names.append("overrideOf")
            case .receivedBy: names.append("receivedBy")
            case .calledBy: names.append("calledBy")
            case .extendedBy: names.append("extendedBy")
            case .accessorOf: names.append("accessorOf")
            case .containedBy: names.append("containedBy")
            case .IBTypeOf: names.append("IBTypeOf")
            case .specializationOf: names.append("specializationOf")
            default: names.append("UNKNOWN")
            }
        }

        return names.joined(separator: ", ")
    }
}

public typealias SymbolProperty = indexstore_symbol_property_t

public extension SymbolProperty {
    static let generic = INDEXSTORE_SYMBOL_PROPERTY_GENERIC
    static let templatePartialSpecialization = INDEXSTORE_SYMBOL_PROPERTY_TEMPLATE_PARTIAL_SPECIALIZATION
    static let templateSpecialization = INDEXSTORE_SYMBOL_PROPERTY_TEMPLATE_SPECIALIZATION
    static let unitTest = INDEXSTORE_SYMBOL_PROPERTY_UNITTEST
    static let IBAnnotated = INDEXSTORE_SYMBOL_PROPERTY_IBANNOTATED
    static let IBOutletCollection = INDEXSTORE_SYMBOL_PROPERTY_IBOUTLETCOLLECTION
    static let GKInspectable = INDEXSTORE_SYMBOL_PROPERTY_GKINSPECTABLE
    static let local = INDEXSTORE_SYMBOL_PROPERTY_LOCAL
    static let protocolInterface = INDEXSTORE_SYMBOL_PROPERTY_PROTOCOL_INTERFACE
    static let swiftAsync = INDEXSTORE_SYMBOL_PROPERTY_SWIFT_ASYNC
}

public typealias SymbolKind = indexstore_symbol_kind_t

public extension SymbolKind {
    static let unknown = INDEXSTORE_SYMBOL_KIND_UNKNOWN
    static let module = INDEXSTORE_SYMBOL_KIND_MODULE
    static let namespace = INDEXSTORE_SYMBOL_KIND_NAMESPACE
    static let namespaceAlias = INDEXSTORE_SYMBOL_KIND_NAMESPACEALIAS
    static let macro = INDEXSTORE_SYMBOL_KIND_MACRO
    static let `enum` = INDEXSTORE_SYMBOL_KIND_ENUM
    static let `struct` = INDEXSTORE_SYMBOL_KIND_STRUCT
    static let `class` = INDEXSTORE_SYMBOL_KIND_CLASS
    static let `protocol` = INDEXSTORE_SYMBOL_KIND_PROTOCOL
    static let `extension` = INDEXSTORE_SYMBOL_KIND_EXTENSION
    static let union = INDEXSTORE_SYMBOL_KIND_UNION
    static let `typealias` = INDEXSTORE_SYMBOL_KIND_TYPEALIAS
    static let function = INDEXSTORE_SYMBOL_KIND_FUNCTION
    static let variable = INDEXSTORE_SYMBOL_KIND_VARIABLE
    static let field = INDEXSTORE_SYMBOL_KIND_FIELD
    static let enumConstant = INDEXSTORE_SYMBOL_KIND_ENUMCONSTANT
    static let instanceMethod = INDEXSTORE_SYMBOL_KIND_INSTANCEMETHOD
    static let classMethod = INDEXSTORE_SYMBOL_KIND_CLASSMETHOD
    static let staticMethod = INDEXSTORE_SYMBOL_KIND_STATICMETHOD
    static let instanceProperty = INDEXSTORE_SYMBOL_KIND_INSTANCEPROPERTY
    static let classProperty = INDEXSTORE_SYMBOL_KIND_CLASSPROPERTY
    static let staticProperty = INDEXSTORE_SYMBOL_KIND_STATICPROPERTY
    static let constructor = INDEXSTORE_SYMBOL_KIND_CONSTRUCTOR
    static let destructor = INDEXSTORE_SYMBOL_KIND_DESTRUCTOR
    static let conversionFunction = INDEXSTORE_SYMBOL_KIND_CONVERSIONFUNCTION
    static let parameter = INDEXSTORE_SYMBOL_KIND_PARAMETER
    static let using = INDEXSTORE_SYMBOL_KIND_USING

    static let commentTag = INDEXSTORE_SYMBOL_KIND_COMMENTTAG
}

extension SymbolKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case INDEXSTORE_SYMBOL_KIND_UNKNOWN: return "unknown"
        case INDEXSTORE_SYMBOL_KIND_MODULE: return "module"
        case INDEXSTORE_SYMBOL_KIND_NAMESPACE: return "namespace"
        case INDEXSTORE_SYMBOL_KIND_NAMESPACEALIAS: return "namespaceAlias"
        case INDEXSTORE_SYMBOL_KIND_MACRO: return "macro"
        case INDEXSTORE_SYMBOL_KIND_ENUM: return "enum"
        case INDEXSTORE_SYMBOL_KIND_STRUCT: return "struct"
        case INDEXSTORE_SYMBOL_KIND_CLASS: return "class"
        case INDEXSTORE_SYMBOL_KIND_PROTOCOL: return "protocol"
        case INDEXSTORE_SYMBOL_KIND_EXTENSION: return "extension"
        case INDEXSTORE_SYMBOL_KIND_UNION: return "union"
        case INDEXSTORE_SYMBOL_KIND_TYPEALIAS: return "typealias"
        case INDEXSTORE_SYMBOL_KIND_FUNCTION: return "function"
        case INDEXSTORE_SYMBOL_KIND_VARIABLE: return "variable"
        case INDEXSTORE_SYMBOL_KIND_FIELD: return "field"
        case INDEXSTORE_SYMBOL_KIND_ENUMCONSTANT: return "enumConstant"
        case INDEXSTORE_SYMBOL_KIND_INSTANCEMETHOD: return "instanceMethod"
        case INDEXSTORE_SYMBOL_KIND_CLASSMETHOD: return "classMethod"
        case INDEXSTORE_SYMBOL_KIND_STATICMETHOD: return "staticMethod"
        case INDEXSTORE_SYMBOL_KIND_INSTANCEPROPERTY: return "instanceProperty"
        case INDEXSTORE_SYMBOL_KIND_CLASSPROPERTY: return "classProperty"
        case INDEXSTORE_SYMBOL_KIND_STATICPROPERTY: return "staticProperty"
        case INDEXSTORE_SYMBOL_KIND_CONSTRUCTOR: return "constructor"
        case INDEXSTORE_SYMBOL_KIND_DESTRUCTOR: return "destructor"
        case INDEXSTORE_SYMBOL_KIND_CONVERSIONFUNCTION: return "conversionFunction"
        case INDEXSTORE_SYMBOL_KIND_PARAMETER: return "parameter"
        case INDEXSTORE_SYMBOL_KIND_USING: return "using"
        case INDEXSTORE_SYMBOL_KIND_COMMENTTAG: return "commentTag"
        default: return "UNIDENTIFIED"
        }
    }
}

public typealias SymbolSubkind = indexstore_symbol_subkind_t

public extension SymbolSubkind {
    static let none = INDEXSTORE_SYMBOL_SUBKIND_NONE
    static let cxxCopyConstructor = INDEXSTORE_SYMBOL_SUBKIND_CXXCOPYCONSTRUCTOR
    static let cxxMoveConstructor = INDEXSTORE_SYMBOL_SUBKIND_CXXMOVECONSTRUCTOR
    static let accessorGetter = INDEXSTORE_SYMBOL_SUBKIND_ACCESSORGETTER
    static let accessorSetter = INDEXSTORE_SYMBOL_SUBKIND_ACCESSORSETTER
    static let usingTypeName = INDEXSTORE_SYMBOL_SUBKIND_USINGTYPENAME
    static let usingValue = INDEXSTORE_SYMBOL_SUBKIND_USINGVALUE
    static let usingEnum = INDEXSTORE_SYMBOL_SUBKIND_USINGENUM

    static let swiftAccessorWillSet = INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORWILLSET
    static let swiftAccessorDidSet = INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORDIDSET
    static let swiftAccessorAddressor = INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORADDRESSOR
    static let swiftAccessorMutableAddressor = INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORMUTABLEADDRESSOR
    static let swiftExtensionOfStruct = INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFSTRUCT
    static let swiftExtensionOfClass = INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFCLASS
    static let swiftExtensionOfEnum = INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFENUM
    static let swiftExtensionOfProtocol = INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFPROTOCOL
    static let swiftPrefixOperator = INDEXSTORE_SYMBOL_SUBKIND_SWIFTPREFIXOPERATOR
    static let swiftPostfixOperator = INDEXSTORE_SYMBOL_SUBKIND_SWIFTPOSTFIXOPERATOR
    static let swiftInfixOperator = INDEXSTORE_SYMBOL_SUBKIND_SWIFTINFIXOPERATOR
    static let swiftSubscript = INDEXSTORE_SYMBOL_SUBKIND_SWIFTSUBSCRIPT
    static let swiftAssociatedType = INDEXSTORE_SYMBOL_SUBKIND_SWIFTASSOCIATEDTYPE
    static let swiftGenericParameter = INDEXSTORE_SYMBOL_SUBKIND_SWIFTGENERICTYPEPARAM
    static let swiftAccessorRead = INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORREAD
    static let swiftAccessorModify = INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORMODIFY
}

extension SymbolSubkind: CustomStringConvertible {
    public var description: String {
        switch self {
        case INDEXSTORE_SYMBOL_SUBKIND_NONE: return "none"
        case INDEXSTORE_SYMBOL_SUBKIND_CXXCOPYCONSTRUCTOR: return "cxxCopyConstructor"
        case INDEXSTORE_SYMBOL_SUBKIND_CXXMOVECONSTRUCTOR: return "cxxMoveConstructor"
        case INDEXSTORE_SYMBOL_SUBKIND_ACCESSORGETTER: return "accessorGetter"
        case INDEXSTORE_SYMBOL_SUBKIND_ACCESSORSETTER: return "accessorSetter"
        case INDEXSTORE_SYMBOL_SUBKIND_USINGTYPENAME: return "usingTypeName"
        case INDEXSTORE_SYMBOL_SUBKIND_USINGVALUE: return "usingValue"
        case INDEXSTORE_SYMBOL_SUBKIND_USINGENUM: return "usingEnum"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORWILLSET: return "swiftAccessorWillSet"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORDIDSET: return "swiftAccessorDidSet"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORADDRESSOR: return "swiftAccessorAddressor"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORMUTABLEADDRESSOR: return "swiftAccessorMutableAddressor"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFSTRUCT: return "swiftExtensionOfStruct"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFCLASS: return "swiftExtensionOfClass"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFENUM: return "swiftExtensionOfEnum"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTEXTENSIONOFPROTOCOL: return "swiftExtensionOfProtocol"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTPREFIXOPERATOR: return "swiftPrefixOperator"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTPOSTFIXOPERATOR: return "swiftPostfixOperator"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTINFIXOPERATOR: return "swiftInfixOperator"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTSUBSCRIPT: return "swiftSubscript"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTASSOCIATEDTYPE: return "swiftAssociatedType"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTGENERICTYPEPARAM: return "swiftGenericParameter"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORREAD: return "swiftAccessorRead"
        case INDEXSTORE_SYMBOL_SUBKIND_SWIFTACCESSORMODIFY: return "swiftAccessorModify"
        default: return "UNIDENTIFIED"
        }
    }
}

public typealias DependencyKind = indexstore_unit_dependency_kind_t

public extension DependencyKind {
    static let unit = INDEXSTORE_UNIT_DEPENDENCY_UNIT
    static let record = INDEXSTORE_UNIT_DEPENDENCY_RECORD
    static let file = INDEXSTORE_UNIT_DEPENDENCY_FILE
}
