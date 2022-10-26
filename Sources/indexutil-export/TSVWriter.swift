import Foundation

class TSVWriter {
    private let output: OutputStream

    init?(_ url: URL) {
        guard let output = OutputStream(url: url, append: false) else {
            return nil
        }
        self.output = output
        self.output.open()
    }

    deinit {
        self.output.close()
    }

    func write(_ fields: CustomStringConvertible...) {
        let strings = fields.map { $0.description }
        let tsv = strings.joined(separator: "\t")
        self.output.write(tsv, maxLength: tsv.utf8.count)
        self.output.write("\n", maxLength: 1)
    }
}
