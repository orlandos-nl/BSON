import Foundation

#if os(Linux)
    internal typealias ProcessInfo = NSProcessInfo
    public typealias Date = NSDate
    public typealias Data = NSData
    
    extension String {
        struct Encoding {
            internal static let utf8 = NSUTF8StringEncoding
        }
    }

    extension NSData {
        internal var count: Int {
            return self.length
        }
        
        internal func copyBytes(to pointer: UnsafeMutablePointer<UInt8>, count: Int) {
            self.getBytes(pointer, length: count)
        }
        
        /// Initialize a `Data` with copied memory content.
        ///
        /// - parameter bytes: A pointer to the memory. It will be copied.
        /// - parameter count: The number of bytes to copy.
        internal convenience init(bytes: UnsafePointer<Void>, count: Int) {
            self.init(bytes: bytes, length: count)
        }
        
        internal convenience init(bytes: [UInt8]) {
            var bytes = bytes
            self.init(bytes: &bytes, count: bytes.count)
        }
        
        /// Initialize a `Data` from a Base-64 encoded String using the given options.
        ///
        /// Returns nil when the input is not recognized as valid Base-64.
        /// - parameter base64String: The string to parse.
        /// - parameter options: Decoding options. Default value is `[]`.
        internal convenience init?(base64Encoded base64String: String, options: [UInt8] = []) {
            self.init(base64Encoded: base64String, options: [])
        }
    }
#endif
