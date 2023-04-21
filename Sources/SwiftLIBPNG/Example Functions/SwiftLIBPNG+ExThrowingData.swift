//
//  SwiftLIBPNG+ExThrowingData.swift
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
    public static func pngForRGBAData(for pixelData:[UInt8], width:UInt32, height:UInt32, bitDepth:UInt8 = 8) throws -> Data {
        var pixelsCopy = pixelData //TODO: This or inout? OR... is there away around need for MutableCopy?
        let bitDepth:UInt8 = 8 //(1 byte, values 1, 2, 4, 8, or 16) (has to be 8 or 16 for RGBA)
        let colorType = PNG_COLOR_TYPE_RGBA //UInt8(6), (1 byte, values 0, 2, 3, 4, or 6) (6 == red, green, blue and alpha)
        
        
        var pngIOBuffer = Data()
        withUnsafePointer(to: pngIOBuffer) { print("io buffer declared: \($0)") }
        
        var png_ptr:OpaquePointer? = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if (png_ptr == nil) { throw PNGError.outOfMemory }
        
        var info_ptr:OpaquePointer? = png_create_info_struct(png_ptr);
        if (info_ptr == nil) {
            png_destroy_write_struct(&png_ptr, nil);
            throw PNGError.outOfMemory;
        }
        
        
        //TODO: Will setWriteBehavior ever throw?
        //underlying libpng function calls png_warning, but not png_error.
        do {
            try setWriteBehavior(png_ptr: png_ptr, bufferPointer: &pngIOBuffer, write_callback: writeDataCallback, flush_callback: nil)
            
        } catch {
            png_destroy_write_struct(&png_ptr, &info_ptr);
            throw PNGError.message("Couldn't set callbacks")
        }
        
        //Can call libpng function directly because it cannot fail i.e.
        //no png_warning(), no png_error() in actual function.
        //Can give it a bad value as a call back pointer, but it will take it without verification.
        png_set_write_status_fn(png_ptr) { png_ptr, row, pass in
            print(png_ptr ?? "nil", row, pass)
        }
    
        //---------------------------------------------------------------- IHDR
        try setIHDR(png_ptr: png_ptr!, info_ptr: info_ptr!, width: width, height: height, bitDepth: Int32(bitDepth), colorType: colorType)
        
        
        //Note, if instead we were doing the "long form" save we could change the compression
        //schemes mid image. (And this is why you use ImageMagick...)
        try pixelsCopy.withUnsafeMutableBufferPointer{ pd_pointer in
            var row_pointers:[Optional<UnsafeMutablePointer<UInt8>>] = []
            for rowIndex in 0..<height {
                let rowStart = rowIndex * width * 4
                row_pointers.append(pd_pointer.baseAddress! + Int(rowStart))
            }
            
            try setRows(png_ptr: png_ptr, info_ptr: info_ptr, rowPointers: &row_pointers)
            try pushPNGData(png_ptr: png_ptr, info_ptr: info_ptr, transforms: PNG_TRANSFORM_IDENTITY, params: nil)
        }
        
        
        //--------------------------------------------------------   PNG CLEANUP
        png_destroy_write_struct(&png_ptr, &info_ptr);
        //---------------------------------------------------------------------
        
        return pngIOBuffer
    }
    

    
    
    //Needs Cleanup
    //Uncessary because underlying libpng function does not jump.
//    static func setWriteStatusUpdateBehavior(
//        png_ptr:OpaquePointer?,
//        status_callback:@convention(c) (Optional<OpaquePointer>, UInt32, Int32) -> ()
//    ) throws {
//
//        let result = pngb_set_write_status_fn(png_ptr, status_callback)
//        if result != 0 {
//            throw PNGError(result)
//        }
//    }
}
