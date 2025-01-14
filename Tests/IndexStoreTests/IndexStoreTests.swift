import XCTest
import IndexStore

final class IndexStoreTests: XCTestCase {
    func testMissingIndexStore() {
        XCTAssertThrowsError(try IndexStore(path: "does/not/exist"))
    }

    func testExerciseIndexStore() throws {
        var hasUnits = false
        var hasRecords = false

        let store = try IndexStore(path: determineIndexStorePath())
        for unitReader in store.units {
            hasUnits = true

            for recordName in unitReader.recordNames {
                // Just find one record we know has some reasonable content
                guard recordName.hasPrefix("IndexStoreTests.swift") ||
                    recordName.hasPrefix("main.swift") else {
                    continue
                }

                guard let recordReader = try? RecordReader(indexStore: store, recordName: recordName) else {
                    continue
                }

                hasRecords = true

                var symbolUSRs: [String] = []
                recordReader.forEach { (symbol: Symbol) in
                    symbolUSRs.append(symbol.usr)
                }
                XCTAssertGreaterThan(symbolUSRs.count, 0)

                var occurrenceUSRs: Set<String> = []
                recordReader.forEach { (symbolOccurrence: SymbolOccurrence) in
                    occurrenceUSRs.insert(symbolOccurrence.symbol.usr)
                }
                XCTAssertGreaterThan(occurrenceUSRs.count, 0)

                XCTAssertTrue(occurrenceUSRs.isSubset(of: symbolUSRs))
            }
        }

        XCTAssertTrue(hasUnits)
        XCTAssertTrue(hasRecords)
    }
}
