//
//  SwiftLIBPNG+SimpleReading.swift
//  
//
//  Created by Carlyn Maw on 4/6/23.
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

import png

//http://www.libpng.org/pub/png/libpng-manual.txt
// Text with //DOC: prefix is from the documentation above.

extension SwiftLIBPNG {
    
    //TODO: This code (is expected to) hard crash if the file is not a valid PNG. See `Why no setjmp??` note
    
    //NOT using "libpng simplified API"
    public static func simpleFileRead(from path:String) throws -> [UInt8] {
        
        let file_ptr = fopen(path, "r")
        if file_ptr == nil {
            throw PNGError("File pointer not available")
        }
        
        //Make the pointer for storing the png's current state struct.
        //Using this function tells libpng to expect to handle memory management, but `png_destroy_read_struct` will still need to be called.
        //takes the version string define, and some pointers that will override rides to default error handling that are not used in this simple case.
        /*C:-- png_create_read_struct(
         user_png_ver: png_const_charp!,
         error_ptr: png_voidp!,
         error_fn: png_error_ptr! (png_structp?, png_const_charp?) -> Void,
         warn_fn: png_error_ptr!  (png_structp?, png_const_charp?) -> Void)
         */
        var png_ptr:OpaquePointer? = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil,
                                                            nil);
        if (png_ptr == nil) { throw PNGError.outOfMemory }
        
        //Makes the pointer to handle information about how the underlying PNG data needs to be manipulated.
        //C:-- png_create_info_struct(png_const_structrp!)
        var info_ptr:OpaquePointer? = png_create_info_struct(png_ptr);
        if (info_ptr == nil) {
            png_destroy_read_struct(&png_ptr, nil, nil); //TODO: not all examples do this
            throw PNGError.outOfMemory;
        }
        
        //## Why no setjmp??
        //In a lot of code you'll see references to
        //`if (setjmp(png_jmpbuf(png_ptr))) { /* DO THIS */ }` here.
        //This overrides the default error handling if the file received is not a PNG file.
        //The default is to hard crash, which isn't great, so it makes sense to override it.
        //However, this feature is turned off by default now since it is not thread safe starting with libpng-1.6.0
        
        //Search for "Setjmp/longjmp issues"
        //https://github.com/glennrp/libpng/blob/12222e6fbdc90523be77633ed430144cfee22772/INSTALL
        //IF you set your compiler flags to allow this feature, I believe png_set_longjmp_fn is the new way to set this function.
        
        //In the mean time your code should make sure to verify that the file path does indeed point to a PNG file before calling this function.
        
        //set destination pointer and file source pointer
        //C:-- png_init_io(png_ptr: png_structrp!, fp: png_FILE_p!)
        png_init_io(png_ptr, file_ptr);
        
        //If you don't want to use fileio , can instead
        /*C:-- png_set_read_fn(
         png_ptr: png_structrp!,
         io_ptr: png_voidp!,
         read_data_fn: png_rw_ptr! (png_structp?, png_bytep?, Int) -> Void)
         */
        //TODO:(see write for example)
        
        
        //Optional: If you used the file stream already and pulled off the file signature for verification purposes, tell the reader it's been done already.
        //png_set_sig_bytes(png_ptr, number);
        
        //Optional: One can also decide how to handle CRC errors (possible bad chunks. )
        //png_set_crc_action(png_ptr, crit_action, ancil_action);
        
        //Other Options: Setting size limits, how to handle chunks that are not defined by the spec
        
        
        //Optional: Set a row-completion handler
        //`pointer` is the png_ptr
        //`row` is the NEXT row number
        //`pass` is always 0 in non interlaced pngs, but also refers to the NEXT row's pass count.
        let rowCompleteCallback:@convention(c) (OpaquePointer?, UInt32, Int32) -> () = { png_ptr, row, pass in
            print(png_ptr ?? "nil", row, pass)
        }
        png_set_read_status_fn(png_ptr, rowCompleteCallback);
        
        //Optional: Do a lot of setting of gamma and alpha handling for your system.
        //Possibly overridden by PNG settings, in some situations.
        //No example code provided.
        
        
        //This is a SIMPLE read. Assumes
        //- the entire file can be _all_ loaded into memory, all at once
        //- that this can be done before any header info needed
        //- don't want to malloc your own row storage
        //- don't need to do successive transforms on the data at read in
        //- any transform you want to do has PNG_TRANSFORM_ define
        
        //Set what transforms desired. If any
        //TODO: Bit print out of masks.
        let png_transforms = PNG_TRANSFORM_IDENTITY //No transforms
        
        //DOC: This call is equivalent to png_read_info(), followed the set of transformations indicated by the transform mask, then png_read_image(), and finally png_read_end().
        png_read_png(png_ptr, info_ptr, png_transforms, nil)
        
        //DOC: If you don't allocate row_pointers ahead of time, png_read_png() will do it, and it'll be free'ed by libpng when you call png_destroy_*().
        let row_pointers = png_get_rows(png_ptr, info_ptr)
        
        //TODO: What happens to end info if no end_info struct? Double make sure is in info_ptr. (doc says it will be.)
        
        let width = png_get_image_width(png_ptr,info_ptr)
        let height = png_get_image_height(png_ptr,info_ptr)
        let color_type_code = png_get_color_type(png_ptr, info_ptr)
        let bit_depth = png_get_bit_depth(png_ptr, info_ptr)
        let channel_count = png_get_channels(png_ptr, info_ptr)
        let row_byte_width = png_get_rowbytes(png_ptr, info_ptr)
        
        print("""
                width: \(width),
                height: \(height),
                colorType: \(color_type_code),
                bitDepth: \(bit_depth),
                channelCount: \(channel_count),
                rowByteWidth: \(row_byte_width)
        """)
        //let pixel_width = channelCountFor(colorTypeCode: color_type_code) * UInt32(bit_depth)
        
        var imagePixels:[UInt8] = []
        let imageRows = UnsafeBufferPointer(start: row_pointers, count: Int(height))
        
        for rowPointer in imageRows {
            
            let rowBufferPtr = UnsafeBufferPointer(start: rowPointer, count: row_byte_width)
            imagePixels.append(contentsOf: rowBufferPtr)
        }
        
        //-------------------------------------------------------   PNG CLEANUP
        
        //if set end_info nuke that too. DO NOT free row_pointers since used `png_get_rows`
        png_destroy_read_struct(&png_ptr, &info_ptr, nil);
        fclose(file_ptr)
        
        //---------------------------------------------------------------------
        
        return imagePixels
        
    }
    
    
    
    
}


