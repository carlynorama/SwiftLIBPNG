#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png

public struct SwiftLIBPNG {
    //http://www.libpng.org/pub/png/book/chapter08.html#png.ch08.tbl.1
    static let pngFileSignature:Data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    
    
    
    public init() {
    }
    
    public static func version() {
        let version = png_access_version_number()
        print(version)
    }
}
    
 
