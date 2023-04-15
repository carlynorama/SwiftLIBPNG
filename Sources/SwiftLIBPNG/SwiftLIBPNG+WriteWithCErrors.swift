//
//  File.swift
//
//
//  Created by Carlyn Maw on 4/15/23.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation

import png
import CBridgePNG


extension SwiftLIBPNG {
    public static func writeWithJumpdefs(width:UInt32, height:UInt32, pixelData:[UInt8]) throws -> Data {
        var pixelsCopy = pixelData //TODO: This or inout? OR... is there away around need for MutableCopy?
        let bitDepth:UInt8 = 1 //(1 byte, values 1, 2, 4, 8, or 16) (has to be 8 or 16 for RGBA)
        let colorType = PNG_COLOR_TYPE_RGBA //UInt8(6), (1 byte, values 0, 2, 3, 4, or 6) (6 == red, green, blue and alpha)


        var pngIOBuffer = Data() //:[UInt8] = [] // //
        withUnsafePointer(to: pngIOBuffer) { print("io buffer declared: \($0)") }

        var png_ptr:OpaquePointer? = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if (png_ptr == nil) { throw PNGError.outOfMemory }

        var info_ptr:OpaquePointer? = png_create_info_struct(png_ptr);
        if (info_ptr == nil) {
            png_destroy_write_struct(&png_ptr, nil);
            throw PNGError.outOfMemory;
        }
        
        print("before")
        pngb_set_default_data_write_exit(&png_ptr, &info_ptr)
        print("after")
    
        
        png_set_write_fn(png_ptr, &pngIOBuffer, writeDataCallback, nil)
        
        png_set_write_status_fn(png_ptr) { png_ptr, row, pass in
            print(png_ptr ?? "nil", row, pass)
        }
        
        print("right before hdr")
        //---------------------------------------------------------------- IHDR
        let result = writeIHDR(png_ptr: png_ptr!, info_ptr: info_ptr!, width: width, height: height, bitDepth: Int32(bitDepth), colorType: colorType)
        
        
        if result == 0 {
            //Note, if instead we were doing the "long form" save we could change the compression
            //schemes mid image. (And this is why you use ImageMagick...)
            pixelsCopy.withUnsafeMutableBufferPointer{ pd_pointer in
                var row_pointers:[Optional<UnsafeMutablePointer<UInt8>>] = []
                for rowIndex in 0..<height {
                    let rowStart = rowIndex * width * 4
                    row_pointers.append(pd_pointer.baseAddress! + Int(rowStart))
                }
                
                //png_set_rows(png_ptr: png_const_structrp!, info_ptr: png_inforp!, row_pointers: png_bytepp!)
                png_set_rows(png_ptr, info_ptr, &row_pointers)
                
                //high level write.
                //TODO: Confirm theory has to be inside so row pointers still valid.
                png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, nil)
            }
            
            //--------------------------------------------------------   PNG CLEANUP
            png_destroy_write_struct(&png_ptr, &info_ptr);
            //---------------------------------------------------------------------
            
            
        } else {
            print("destroying struct: \(png_ptr), \(info_ptr)")
            png_destroy_write_struct(&png_ptr, &info_ptr);
            throw PNGError(result)
        }
        

        return pngIOBuffer
    }
    
    static func writeIHDR(png_ptr:OpaquePointer, info_ptr:OpaquePointer, width:UInt32, height:UInt32,
    bitDepth:Int32, colorType:Int32) -> CInt {
        png_set_IHDR(png_ptr, info_ptr, width, height,
                     Int32(bitDepth), colorType,
                     PNG_INTERLACE_NONE,
                     PNG_COMPRESSION_TYPE_DEFAULT,
                     PNG_FILTER_TYPE_DEFAULT
        )
        
        return 0
    }
}
