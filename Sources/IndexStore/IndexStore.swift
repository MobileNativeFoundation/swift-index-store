import Foundation
import CIndexStore

// About the use of `*_apply_f` functions.
//
// The C indexstore API provides functions that take blocks (closures), which are named `*_apply`. The API
// also has variants that take a raw C callback function, which are named `*_apply_f`. Ideally, this Swift
// wrapper would use the closure variants, but for Linux portability it uses C function callbacks.
//
// C functions don't capture variables, which is why the `apply_f` API takes a context pointer. The Context
// types are used for calling the `apply_f` functions:
//
// The key points are:
//   1. A context is created
//   2. The context is passed by pointer to the `apply_f` function
//   3. The context is unpacked
//   4. If necessary the callback closure is called using withoutActuallyEscaping

private class Context<Callback, Parent: AnyObject> {
    unowned var this: Parent
    let callback: Callback

    init(callback: Callback, this: Parent) {
        self.callback = callback
        self.this = this
    }

    func pointer() -> UnsafeMutableRawPointer {
        unsafeBitCast(Unmanaged.passUnretained(self), to: UnsafeMutableRawPointer.self)
    }

    static func cast(_ pointer: UnsafeMutableRawPointer!) -> Context<Callback, Parent> {
        Unmanaged<Context<Callback, Parent>>.fromOpaque(pointer).takeUnretainedValue()
    }
}

public final class IndexStore {
    fileprivate let store: indexstore_t

    public init(path: String) throws {
        let fullPath = (path as NSString).expandingTildeInPath
        var error: indexstore_error_t?
        if let store = indexstore_store_create(fullPath, &error) {
            self.store = store
        } else {
            throw IndexStoreError(error!)
        }
    }

    deinit {
        indexstore_store_dispose(self.store)
    }

    public var unitNames: [String] {
        var unitNames = [String]()
        let context = Context(callback: { unitNames.append($0) }, this: self)
        let pointer = context.pointer()

        indexstore_store_units_apply_f(self.store, /*unsorted*/0, pointer) { pointer, unitName in
            let context = Context<(String) -> Void, IndexStore>.cast(pointer)
            context.callback(String(unitName))
            return true
        }

        return unitNames
    }

    public var units: UnitReaderSequence {
        return UnitReaderSequence(indexStore: self)
    }

    public struct UnitReaderSequence: Sequence {
        let indexStore: IndexStore

        public func makeIterator() -> Iterator {
            return Iterator(self.indexStore)
        }

        public struct Iterator: IteratorProtocol {
            private let indexStore: IndexStore
            private var unitNames: Array<String>.Iterator

            fileprivate init(_ indexStore: IndexStore) {
                self.indexStore = indexStore
                self.unitNames = indexStore.unitNames.makeIterator()
            }

            public mutating func next() -> UnitReader? {
                guard let unitName = self.unitNames.next() else {
                    return nil
                }

                do {
                    return try UnitReader(indexStore: self.indexStore, unitName: unitName)
                } catch {
                    // This is not expected to occur. If the IndexStore gives a unit name, it should exist.
                    // This could happen if somehow the unit file is invalid. To handle any errors, call
                    // `next()` for the next `UnitReader`.
                    print("warning: could not read \(unitName) - \(error)", to: &stderr)
                    return self.next()
                }
            }
        }
    }
}

public final class UnitReader {
    private let reader: indexstore_unit_reader_t

    public let name: String

    public init(indexStore: IndexStore, unitName: String) throws {
        var error: indexstore_error_t?
        self.name = unitName
        if let reader = indexstore_unit_reader_create(indexStore.store, unitName, &error) {
            self.reader = reader
        } else {
            throw IndexStoreError(error!)
        }
    }

    deinit {
        indexstore_unit_reader_dispose(self.reader)
    }

    // Not implemented:
    // * indexstore_unit_reader_has_main_file - use mainFile.isEmpty instead
    // * indexstore_unit_reader_get_modification_time - deprecated

    public var isSystem: Bool {
        return indexstore_unit_reader_is_system_unit(self.reader)
    }

    public var isModule: Bool {
        return indexstore_unit_reader_is_module_unit(self.reader)
    }

    public var isSource: Bool {
        return !self.isModule
    }

    public var isDebugCompilation: Bool {
        return indexstore_unit_reader_is_debug_compilation(self.reader)
    }

    public private(set) lazy var mainFile = String(indexstore_unit_reader_get_main_file(self.reader))

    public private(set) lazy var moduleName = String(indexstore_unit_reader_get_module_name(self.reader))

    public var workingDirectory: String { String(indexstore_unit_reader_get_working_dir(self.reader)) }

    public var outputFile: String { String(indexstore_unit_reader_get_output_file(self.reader)) }

    public var sysrootPath: String { String(indexstore_unit_reader_get_sysroot_path(self.reader)) }

    public var target: String { String(indexstore_unit_reader_get_target(self.reader)) }

    public var providerIdentifier: String { String(indexstore_unit_reader_get_provider_identifier(self.reader)) }

    public var providerVersion: String { String(indexstore_unit_reader_get_provider_version(self.reader)) }

    public var recordNames: [String] {
        var recordNames: [String] = []
        self.forEach { unitDependency in
            if unitDependency.kind == .record {
                recordNames.append(unitDependency.name)
            }
        }
        return recordNames
    }

    public var recordName: String? {
        var recordName: String?
        self.forEach { unitDependency in
            if unitDependency.kind == .record && unitDependency.filePath == self.mainFile {
                recordName = unitDependency.name
            }
        }
        return recordName
    }

    public func forEach(dependency callback: (UnitDependency) -> Void) {
        withoutActuallyEscaping(callback) { callback in
            let context = Context(callback: callback, this: self)
            let pointer = context.pointer()
            indexstore_unit_reader_dependencies_apply_f(self.reader, pointer) { pointer, unitDependency in
                if let unitDependency = unitDependency {
                    let context = Context<(UnitDependency) -> Void, UnitReader>.cast(pointer)
                    context.callback(UnitDependency(context.this, unitDependency))
                }
                return true
            }
        }
    }
}

public final class UnitDependency {
    private let unitReader: UnitReader
    private let unitDependency: indexstore_unit_dependency_t

    public let name: String

    fileprivate init(_ unitReader: UnitReader, _ unitDependency: indexstore_unit_dependency_t) {
        self.unitReader = unitReader
        self.unitDependency = unitDependency

        self.name = String(indexstore_unit_dependency_get_name(self.unitDependency))
    }

    public var kind: DependencyKind {
        return indexstore_unit_dependency_get_kind(self.unitDependency)
    }

    public private(set) lazy var moduleName = String(indexstore_unit_dependency_get_modulename(self.unitDependency))

    public var isSystem: Bool {
        return indexstore_unit_dependency_is_system(self.unitDependency)
    }

    public private(set) lazy var filePath = String(indexstore_unit_dependency_get_filepath(self.unitDependency))
}

public final class RecordReader {
    private let reader: indexstore_record_reader_t

    public let name: String

    public init(indexStore: IndexStore, recordName: String) throws {
        var error: indexstore_error_t?
        self.name = recordName
        if let reader = indexstore_record_reader_create(indexStore.store, recordName, &error) {
            self.reader = reader
        } else {
            throw IndexStoreError(error!)
        }
    }

    deinit {
        indexstore_record_reader_dispose(self.reader)
    }

    public func forEach(symbol callback: (Symbol) -> Void) {
        withoutActuallyEscaping(callback) { callback in
            let context = Context(callback: callback, this: self)
            let pointer = context.pointer()
            indexstore_record_reader_symbols_apply_f(self.reader, /*nocache*/true, pointer) { pointer, symbol in
                if let symbol = symbol {
                    let context = Context<(Symbol) -> Void, RecordReader>.cast(pointer)
                    context.callback(Symbol(context.this, symbol))
                }
                return true
            }
        }
    }

    public func forEach(occurrence callback: (SymbolOccurrence) -> Void) {
        withoutActuallyEscaping(callback) { callback in
            let context = Context(callback: callback, this: self)
            let pointer = context.pointer()
            indexstore_record_reader_occurrences_apply_f(self.reader, pointer) { pointer, occurrence in
                if let occurrence = occurrence {
                    let context = Context<(SymbolOccurrence) -> Void, RecordReader>.cast(pointer)
                    context.callback(SymbolOccurrence(context.this, occurrence))
                }
                return true
            }
        }
    }
}

public final class SymbolOccurrence {
    private let recordReader: RecordReader
    private let occurrence: indexstore_occurrence_t

    public let symbol: Symbol
    public let roles: SymbolRoles

    fileprivate init(_ recordReader: RecordReader, _ occurrence: indexstore_occurrence_t) {
        self.recordReader = recordReader
        self.occurrence = occurrence

        self.symbol = Symbol(self.recordReader, indexstore_occurrence_get_symbol(self.occurrence))
        self.roles = SymbolRoles(indexstore_occurrence_get_roles(self.occurrence))
    }

    public var location: (line: Int, column: Int) {
        var line: UInt32 = UInt32.max
        var column: UInt32 = UInt32.max
        indexstore_occurrence_get_line_col(self.occurrence, &line, &column)
        return (Int(line), Int(column))
    }

    public func forEach(relation callback: (Symbol, SymbolRoles) -> Void) {
        withoutActuallyEscaping(callback) { callback in
            let context = Context(callback: callback, this: self)
            let pointer = context.pointer()

            indexstore_occurrence_relations_apply_f(self.occurrence, pointer) { pointer, relation in
                let context = Context<(Symbol, SymbolRoles) -> Void, SymbolOccurrence>.cast(pointer)
                let symbol = Symbol(context.this.recordReader, indexstore_symbol_relation_get_symbol(relation))
                let roles = SymbolRoles(indexstore_symbol_relation_get_roles(relation))
                context.callback(symbol, roles)
                return true
            }
        }
    }
}

public final class Symbol {
    private let recordReader: RecordReader
    private let symbol: indexstore_symbol_t

    fileprivate init(_ recordReader: RecordReader, _ symbol: indexstore_symbol_t) {
        self.recordReader = recordReader
        self.symbol = symbol
    }

    public private(set) lazy var usr = String(indexstore_symbol_get_usr(self.symbol))

    public private(set) lazy var name = String(indexstore_symbol_get_name(self.symbol))

    public var kind: SymbolKind {
        return indexstore_symbol_get_kind(self.symbol)
    }

    public var subkind: SymbolSubkind {
        return indexstore_symbol_get_subkind(self.symbol)
    }

    public var properties: SymbolProperty {
        return indexstore_symbol_get_properties(self.symbol)
    }

    public var roles: SymbolRoles {
        return SymbolRoles(indexstore_symbol_get_roles(self.symbol))
    }

    public var relatedRoles: SymbolRoles {
        return SymbolRoles(indexstore_symbol_get_related_roles(self.symbol))
    }
}
