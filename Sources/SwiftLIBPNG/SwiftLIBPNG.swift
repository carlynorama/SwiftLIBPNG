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
    
    
    public init() {}
    
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
    
    static func printIOState(pngPointer:OpaquePointer) {
//        /* The flags returned by png_get_io_state() are the following: */
//        #  define PNG_IO_NONE        0x0000   /* no I/O at this moment */
//        #  define PNG_IO_READING     0x0001   /* currently reading */
//        #  define PNG_IO_WRITING     0x0002   /* currently writing */
//        #  define PNG_IO_SIGNATURE   0x0010   /* currently at the file signature */
//        #  define PNG_IO_CHUNK_HDR   0x0020   /* currently at the chunk header */
//        #  define PNG_IO_CHUNK_DATA  0x0040   /* currently at the chunk data */
//        #  define PNG_IO_CHUNK_CRC   0x0080   /* currently at the chunk crc */
//        #  define PNG_IO_MASK_OP     0x000f   /* current operation: reading/writing */
//        #  define PNG_IO_MASK_LOC    0x00f0   /* current location: sig/hdr/data/crc */
//        #endif /* IO_STATE */
        let codeString:String = String(String(String(png_get_io_state(pngPointer), radix:2).reversed()).padding(toLength: 8, withPad: "0", startingAt: 0).reversed())
        //1000010 -> currently writing at the chunk header
        //1000010 -> currently writing at the chunk crc
        print(codeString)
    }
    
    
    
    //MARK: Global Callback Defs
    
    //example row completion callback if an inline closure is not appropriate. Since stored variables are not allowed in extensions these will need to be here.
    
    //`Attribute @convention(c)` can only be applied to types, not declarations
    //    let rowCompleteCallback:@convention(c) (OpaquePointer?, UInt32, Int32) -> () = {png_ptr, row, pass in
    //        print(png_ptr ?? "nil", row, pass)
    //    }
    
    
    
}


