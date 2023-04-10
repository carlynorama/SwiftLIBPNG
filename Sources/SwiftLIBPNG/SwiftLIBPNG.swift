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
    
    

    
    
    //MARK: Global Error Callbacks
    
    struct PNGErrorInfo {
        var png_ptr:OpaquePointer?
        var info_ptr:OpaquePointer?
        var fileHandle:UnsafeMutablePointer<FILE>?
        var testExtraData:UInt32
        
        func print_info() {
            print("\(String(describing: png_ptr)), \(String(describing: info_ptr)), \(String(describing: fileHandle)), \(testExtraData)")
        }
    }

    static let writeErrorCallback:@convention(c) (Optional<OpaquePointer>, Optional<UnsafePointer<CChar>>) -> () = { png_ptr, message in
        if let error_ptr = png_get_error_ptr(png_ptr) {
            print("There was a non nil error pointer set a \(error_ptr)")
            var typed_error_ptr = error_ptr.load(as: PNGErrorInfo.self)//error_ptr.assumingMemoryBound(to: PNGErrorInfo.self)
            typed_error_ptr.print_info()
            //If aborting whole program everything should be freed automatically, but in case not...
            precondition(png_ptr == typed_error_ptr.png_ptr)
            png_destroy_write_struct(&typed_error_ptr.png_ptr, &typed_error_ptr.info_ptr)
            if typed_error_ptr.fileHandle != nil {
                fclose(typed_error_ptr.fileHandle)
            }
        }
    
        if let message {
            print("libpng crashed with warning: \(String(cString: message))")
        } else {
            print("libpng crashed without providing a message.")
        }
        
        //Some way to kill png?
        //How to leave PNG write...
        exit(99)  //see also https://en.cppreference.com/w/c/program/atexit
        //abort() //terminates the process by raising a SIGABRT signal, possible handler?
        
    }
    
    static let writeWarningCallback:@convention(c) (Optional<OpaquePointer>, Optional<UnsafePointer<CChar>>) -> () = { png_ptr, message in
        if let error_ptr = png_get_error_ptr(png_ptr) {
            print("There was a non nil error pointer set a \(error_ptr)")
            
        }
        if let message {
            print("libpng sends warning: \(String(cString: message))")
        } else {
            print("libpng sends unspecified warning")
        }
        
        //Use the error pointer to set flags, etc.
    }
    
    
}


