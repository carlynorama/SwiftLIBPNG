//
//  File.swift
//  
//
//  Created by Labtanza on 4/7/23.
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation

import png

extension SwiftLIBPNG {
    
    //NOT using "libpng simplified API"
    //takes a width, height and pixel data in RR GG BB AA byte order
    public static func buildSimpleDataExample(width:UInt32, height:UInt32, pixelData:[UInt8]) throws -> Data {
        var pixelsCopy = pixelData //TODO: This or inout? OR... is there away around need for MutableCopy?
        let bitDepth:UInt8 = 8 // (1 byte, values 1, 2, 4, 8, or 16) (has to be 8 or 16 for RGBA)
        let colorType = PNG_COLOR_TYPE_RGBA //UInt8(6), (1 byte, values 0, 2, 3, 4, or 6) (6 == red, green, blue and alpha)

        
        var pngIOBuffer = Data()//:[UInt8] = [] // Data() //
        
        //Make the pointer for storing the png's current state struct.
        //Using this function tells libpng to expect to handle memory management, but `png_destroy_write_struct` will still need to be called.
        //takes the version string define, and some pointers that will override rides to default error handling that are not used in this simple case.
        /*C:-- png_create_write_struct(
            user_png_ver: png_const_charp!,
            error_ptr: png_voidp!,
            error_fn: png_error_ptr! (png_structp?, png_const_charp?) -> Void,
            warn_fn: png_error_ptr!  (png_structp?, png_const_charp?) -> Void)
         */
        var png_ptr:OpaquePointer? = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil,
                                              nil);
             if (png_ptr == nil) { throw PNGError.outOfMemory }
        
        //Makes the pointer to handle information about how the underlying PNG data needs to be manipulated.
        //C:-- png_create_info_struct(png_const_structrp!)
        var info_ptr:OpaquePointer? = png_create_info_struct(png_ptr);
        if (info_ptr == nil) {
            png_destroy_write_struct(&png_ptr, nil); //TODO: not all examples do this
            throw PNGError.outOfMemory;
        }
        
        //see simple read for notes on jmpdef
        
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
        
        let writeDataCallback: @convention(c) (Optional<OpaquePointer>, Optional<UnsafeMutablePointer<UInt8>>, Int) -> Void = { png_ptr, data_io_ptr, length in
            guard let output_ptr:UnsafeMutableRawPointer = png_get_io_ptr(png_ptr) else { return }
            guard let data_ptr:UnsafeMutablePointer<UInt8> = data_io_ptr else { return }
            
            //Option 1 with bufferIO tied to Data
            let typed_output_ptr = output_ptr.assumingMemoryBound(to: Data.self)
            typed_output_ptr.pointee.append(data_ptr, count: length)
        }
        
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
        //NOTE: If you need the data "as is" you'll need to look into this because that is not the default scheme.
        //http://www.libpng.org/pub/png/book/chapter09.html
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
        //png_set_rows()

        
        pixelsCopy.withUnsafeMutableBufferPointer{ pd_pointer in
            let nilPointer:Optional<UnsafeMutablePointer<UInt8>> = nil
            var row_pointers = Array(repeating: nilPointer, count: Int(height))
            for rowIndex in 0..<height {
                let rowStart = rowIndex * width * 4
                row_pointers[Int(rowIndex)] = (pd_pointer.baseAddress! + Int(rowStart))
            }

            //png_set_rows(png_ptr: png_const_structrp!, info_ptr: png_inforp!, row_pointers: png_bytepp!)
            png_set_rows(png_ptr, info_ptr, &row_pointers)
            
            //high level write.
            //TODO: Confirm theory has to be inside so row pointers still valid.
            png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, nil)
        }
    

        
        return pngIOBuffer
    }
    
}
