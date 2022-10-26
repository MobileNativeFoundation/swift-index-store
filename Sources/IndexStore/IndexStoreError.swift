import CIndexStore

public final class IndexStoreError: Error, CustomStringConvertible {
    private var error: indexstore_error_t

    init(_ error: indexstore_error_t) {
        self.error = error
    }

    deinit {
        indexstore_error_dispose(self.error)
    }

    public var description: String {
        return String(cString: indexstore_error_get_description(self.error))
    }
}
