#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png

public struct SwiftLIBPNG {
    //http://www.libpng.org/pub/png/book/chapter08.html#png.ch08.tbl.1
    public static let pngFileSignature:[UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    
    
    public init() {
    }
    
    public static func version() {
        let version = png_access_version_number()
        print(version)
    }
    
    public static func versionInfo()
    {
        let test2 = String(format:"   Compiled with libpng %@; using libpng %lu.\n", PNG_LIBPNG_VER_STRING, png_access_version_number())
        print(test2)
        
    }
    
    public static func checkSignature(data:Data, offset:Int = 0) -> Bool {
        withUnsafeBytes(of:data) { bytesPtr in
            if let base = bytesPtr.assumingMemoryBound(to: UInt8.self).baseAddress {
                return isValidSignature(bytePointer: base + offset, start: 0, count: 8)
            } else {
                return false
            }
        }
    }
    
    static func isValidSignature(bytePointer:UnsafePointer<UInt8>, start:Int = 0, count:CInt) -> Bool {
        //png_sig_cmp(T##sig: png_const_bytep!##png_const_bytep!, T##start: Int##Int, T##num_to_check: Int##Int)
        return png_sig_cmp(bytePointer, start, 8) == 0
        
    }
    
}


