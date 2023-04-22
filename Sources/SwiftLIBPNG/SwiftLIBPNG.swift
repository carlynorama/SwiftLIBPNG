#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png
import CBridgePNG

public struct SwiftLIBPNG {
    public typealias ForLibPNG = Int32

    public init() {}

    //TODO: This packages version
    public static func version() {
        let version = png_access_version_number()
        print(version)
    }
    
    public static func libpngVersion() {
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
    
    
    
    //MARK: Data Return Callback
    
    static let writeDataCallback: @convention(c) (Optional<OpaquePointer>, Optional<UnsafeMutablePointer<UInt8>>, Int) -> Void = { png_ptr, data_io_ptr, length in
        guard let output_ptr:UnsafeMutableRawPointer = png_get_io_ptr(png_ptr) else { return }
        guard let data_ptr:UnsafeMutablePointer<UInt8> = data_io_ptr else { return }
        //print("callback io output buffer: \(output_ptr)")
        //print("callback io data buffer: \(data_ptr)")
        
        let typed_output_ptr = output_ptr.assumingMemoryBound(to: Data.self)
        typed_output_ptr.pointee.append(data_ptr, count: length)
    }


    
    //MARK: Global Error Callbacks - used with Example `buildSimpleDataExample`
    
    struct PNGInfoForError {
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
            var typed_error_ptr = error_ptr.load(as: PNGInfoForError.self)//error_ptr.assumingMemoryBound(to: PNGErrorInfo.self)
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

extension SwiftLIBPNG {
    //MARK: Throwing Sub functions
    static func setIHDR(png_ptr:OpaquePointer, info_ptr:OpaquePointer, width:UInt32, height:UInt32,
                        bitDepth:Int32, colorType:Int32) throws {
        let result = pngb_set_IHDR(png_ptr, info_ptr, width, height, bitDepth, colorType,                      PNG_INTERLACE_NONE,
                                   PNG_COMPRESSION_TYPE_DEFAULT,
                                   PNG_FILTER_TYPE_DEFAULT)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
    
    static func setRows(png_ptr:OpaquePointer?, info_ptr:OpaquePointer?, rowPointers:png_bytepp?) throws {
        let result = pngb_set_rows(png_ptr, info_ptr, rowPointers)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
    static func pushPNGData(png_ptr:OpaquePointer?, info_ptr:OpaquePointer?, transforms:Int32, params:Optional<UnsafeMutableRawPointer> = nil) throws {
        let result = pngb_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, params)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
    //Needs Cleanup because underlying libpng function does not take in info_ptr and
    //info ptr is need for destroy.
    static func setWriteBehavior(
        png_ptr:OpaquePointer?,
        bufferPointer:Optional<UnsafeMutableRawPointer>,
        write_callback:@convention(c) (Optional<OpaquePointer>, Optional<UnsafeMutablePointer<UInt8>>, Int) -> Void,
        flush_callback:Optional<@convention(c) (Optional<OpaquePointer>) -> ()>
    ) throws {
        let result = pngb_set_write_fn(png_ptr, bufferPointer, write_callback, flush_callback)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
}


