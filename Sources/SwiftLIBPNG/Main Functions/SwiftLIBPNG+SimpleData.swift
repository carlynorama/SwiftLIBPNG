//
//  SwiftLIBPNG+ExSimpleData.swift
//  
//
//  Created by Carlyn Maw on 4/7/23.
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation

import png


//WARNING: This code (is expected to) hard crash if something goes wrong. The callback functions only print to console and exit() the program. Not suitable for GUI applications. 

extension SwiftLIBPNG {
    // EXAMPLE USAGE
    //    func writeImage() {
    //        let width = 5
    //        let height = 3
    //        var pixelData:[UInt8] = []
    //
    //        for _ in 0..<height {
    //            for _ in 0..<width {
    //                pixelData.append(0x77)
    //                pixelData.append(0x00)
    //                pixelData.append(UInt8.random(in: 0...UInt8.max))
    //                pixelData.append(0xFF)
    //            }
    //        }
    //
    //        let data = try? SwiftLIBPNG.buildSimpleDataExample(width: 5, height: 3, pixelData: pixelData)
    //        if let data {
    //            for item in data {
    //                print(String(format: "0x%02x", item), terminator: "\t")
    //            }
    //            print()
    //
    //            let locationToWrite = URL.documentsDirectory.appendingPathComponent("testImage", conformingTo: .png)
    //            do {
    //                try data.write(to: locationToWrite)
    //            } catch {
    //                print(error.self)
    //            }
    //        }
    //    }
    
    //NOT using "libpng simplified API"
    //takes a width, height and pixel data in RR GG BB AA byte order
    public static func optionalPNGForRGBA(width:UInt32, height:UInt32, pixelData:[UInt8]) -> Data? {
        var pixelsCopy = pixelData //TODO: This or inout? OR... is there away around need for MutableCopy?
        let bitDepth:UInt8 = 8 //(1 byte, values 1, 2, 4, 8, or 16) (has to be 8 or 16 for RGBA)
        let colorType = PNG_COLOR_TYPE_RGBA //UInt8(6), (1 byte, values 0, 2, 3, 4, or 6) (6 == red, green, blue and alpha)
        
        var pngIOBuffer = Data() //:[UInt8] = [] // //
        withUnsafePointer(to: pngIOBuffer) { print("io buffer declared: \($0)") }
        
        var pngWriteErrorInfo = PNGInfoForError(testExtraData: 42)
        
        //Make the pointer for storing the png's current state struct.
        //Using this function tells libpng to expect to handle memory management, but `png_destroy_write_struct` will still need to be called.
        //takes the version string define, and some pointers that will override rides to default error handling that are not used in this simple case.
        /*C:-- png_create_write_struct(
         user_png_ver: png_const_charp!,
         error_ptr: png_voidp!,  //safe to leave as nil if you don't need to pass a message to your error funcs.
         error_fn: png_error_ptr! (png_structp?, png_const_charp?) -> Void,
         warn_fn: png_error_ptr!  (png_structp?, png_const_charp?) -> Void)
         */
        var png_ptr:OpaquePointer? = png_create_write_struct(PNG_LIBPNG_VER_STRING, &pngWriteErrorInfo, writeErrorCallback, writeWarningCallback)
        if (png_ptr == nil) { return nil }
        
        //Makes the pointer to handle information about how the underlying PNG data needs to be manipulated.
        //C:-- png_create_info_struct(png_const_structrp!)
        var info_ptr:OpaquePointer? = png_create_info_struct(png_ptr);
        if (info_ptr == nil) {
            png_destroy_write_struct(&png_ptr, nil);
            return nil
        }
        
        pngWriteErrorInfo.fileHandle = nil
        pngWriteErrorInfo.png_ptr = png_ptr
        pngWriteErrorInfo.info_ptr = info_ptr
        
        //see README for notes on jmpdef
        
        //If writing palletized PNG, see documentation if want to change
        //default palette checking behavior.
        
        //Set the output destination. If writing to file can use png_init_io(png_ptr, file_ptr); as in simpleFileRead or, one can construct a data receiving function and set it with:
        /*C:--png_set_write_fn(
         png_ptr: png_structrp!,
         io_ptr: png_voidp!,
         write_data_fn: png_rw_ptr! (png_structp?, png_bytep?, Int) -> Void,
         output_flush_fn: png_flush_ptr! (png_structp?) -> Void
         )
         */
        

        
        png_set_write_fn(png_ptr, &pngIOBuffer, writeDataCallback, nil)
        
        //if have already handled appending header or otherwise don't need to.
        //png_set_sig_bytes(png_ptr, 8);
        
        //Optional: Set a row-completion handler
        //`pointer` is the png_ptr
        //`row` is the NEXT row number
        //`pass` is always 0 in non interlaced pngs, but also refers to the NEXT row's pass count.
        //READ example uses callback, but also takes closure.
        png_set_write_status_fn(png_ptr) { png_ptr, row, pass in
            print(png_ptr ?? "nil", row, pass)
        }
        
        //Set compression schemes. Don't call to leave as the default. libpng optimizes for a good balance between writing speed and resulting file compression.
        //NOTE: If you need the data "as is", that is not the default scheme.
        //http://www.libpng.org/pub/png/book/chapter09.html
        //https://www.ietf.org/rfc/rfc1951.txt
        //C:--png_set_filter(png_ptr:png_structrp!, method: Int32, filters: Int32)
        
        //---------------------------------------------------------------- IHDR
        png_set_IHDR(png_ptr, info_ptr, width, height,
                     Int32(bitDepth), colorType,
                     PNG_INTERLACE_NONE,
                     PNG_COMPRESSION_TYPE_DEFAULT,
                     PNG_FILTER_TYPE_DEFAULT
        )
        
        //------------------------------------------------------------------
        //Anything it that isn't text or time has to come before IDAT, but it doesn't matter the order.
        //libpng will order them correctly on output.
        
        //---------------------------------------------------------------  IDAT
        
        
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
            //Has to be inside so row pointers still valid.
            png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, nil)
        }
        
        //--------------------------------------------------------   PNG CLEANUP
        png_destroy_write_struct(&png_ptr, &info_ptr);
        //---------------------------------------------------------------------
        
        return pngIOBuffer
    }
    
}
