#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png

public struct SwiftLIBPNG {
    public private(set) var text = "Hello, World!"
    
    public init() {
    }
    
    public static func version() {
        let version = png_access_version_number()
        print(version)
    }
}
