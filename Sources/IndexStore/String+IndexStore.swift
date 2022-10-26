import CIndexStore
import Foundation

extension String {
    init(_ stringRef: indexstore_string_ref_t) {
        guard stringRef.data != nil && stringRef.length > 0 else {
            self = ""
            return
        }

        let buffer = UnsafeRawBufferPointer(start: stringRef.data, count: stringRef.length)
        self.init(decoding: buffer, as: UTF8.self)
    }
}
