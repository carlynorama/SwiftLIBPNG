//
//  SwiftLIBPNG+Throwing.swift
//  
//
//  Created by Carlyn Maw on 4/23/23.
//

// Wrappers for functions in CShimPNG


#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png
import CShimPNG

extension SwiftLIBPNG {
    static func setIHDR(png_ptr:OpaquePointer, info_ptr:OpaquePointer, width:UInt32, height:UInt32,
                        bitDepth:Int32, colorType:Int32) throws {
        let result = pngshim_set_IHDR(png_ptr, info_ptr, width, height, bitDepth, colorType,
                                   PNG_INTERLACE_NONE,
                                   PNG_COMPRESSION_TYPE_DEFAULT,
                                   PNG_FILTER_TYPE_DEFAULT)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
    
    static func setRows(png_ptr:OpaquePointer?, info_ptr:OpaquePointer?, rowPointers:png_bytepp?) throws {
        let result = pngshim_set_rows(png_ptr, info_ptr, rowPointers)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
    static func pushPNGData(png_ptr:OpaquePointer?, info_ptr:OpaquePointer?, transforms:Int32, params:Optional<UnsafeMutableRawPointer> = nil) throws {
        let result = pngshim_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, params)
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
        let result = pngshim_set_write_fn(png_ptr, bufferPointer, write_callback, flush_callback)
        if result != 0 {
            throw PNGError(result)
        }
    }
    
}


