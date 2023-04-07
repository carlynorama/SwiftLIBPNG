//
//  File.swift
//  
//
//  Created by Carlyn Maw on 4/6/23.
//

import Foundation
import png

//http://www.libpng.org/pub/png/libpng-manual.txt

//DOC: The struct at which png_ptr points is used internally by libpng to keep track of the current state of the PNG image at any given moment; info_ptr is used to indicate what its state will be after all of the user-requested transformations are performed. One can also allocate a second information struct, usually referenced via an end_ptr variable; this can be used to hold all of the PNG chunk information that comes after the image data, in case it is important to keep pre- and post-IDAT information separate (as in an image editor, which should preserve as much of the existing PNG structure as possible). For this application, we don't care where the chunk information comes from, so we will forego the end_ptr information struct and direct everything to info_ptr.


extension SwiftLIBPNG {

    //TODO: This code (is expected to) hard crash if the file is not a PNG. See `Why no setjmp??` note
    public func simpleFileRead(from url:URL) throws {
        let file_ptr = fopen(url.relativePath, "r")
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
        //IF you set your compiler flags to allow this feature I believe png_set_longjmp_fn is the new way to set this function.
        
        //In the mean time your code should make sure to verify that the file path does indeed point to a PNG file.
        
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
        
        
        //Optional: Set a row-completion handler
        //pointer is the png_ptr
        //row is the NEXT row number
        //pass is always 0 in non interlaced pngs
        let rowCompleteCallback:@convention(c) (OpaquePointer?, UInt32, Int32) -> () = { png_ptr, row, pass in
            print(png_ptr ?? "nil", row, pass)
        }
        png_set_read_status_fn(png_ptr, rowCompleteCallback);
        
        //Optional: Do a lot of setting of gamma and alpha handling for your system.
        //Possibly overridden by PNG settings, in some situations.
        //No example code provided.
        
        
        //This is a SIMPLE read. Assumes the entire file can be 
        //See documentaion full set of masks that can be applied
        //TODO: Bit print out of masks.
        let png_transforms = PNG_TRANSFORM_IDENTITY //| PNG_TRANSFORM_SWAP_ALPHA
        //DOC: This call is equivalent to png_read_info(), followed the set of transformations indicated by the transform mask, then png_read_image(), and finally png_read_end().
        png_read_png(png_ptr, info_ptr, png_transforms, nil)
        
        //DOC:If you don't allocate row_pointers ahead of time, png_read_png() will do it, and it'll be free'ed by libpng when you call png_destroy_*().
        let row_pointers = png_get_rows(png_ptr, info_ptr)
        //If you allocated your row_pointers in a single block, as suggested above in the description of the high level read interface, you must not transfer responsibility for freeing it to the png_set_rows or png_read_destroy function, because they would also try to free the individual row_pointers[i].
        
        //TODO: What happens to end info make sure is in info_ptr
        
        print(png_get_image_width(png_ptr,
                                  info_ptr))

        print(png_get_image_height(png_ptr,
                                  info_ptr))
        
        
        //if set endinfo do that too
        if png_ptr != nil {
            if info_ptr != nil {
                png_destroy_read_struct(&png_ptr, &info_ptr, nil);
            } else {
                png_destroy_read_struct(&png_ptr, nil, nil);
            }
        }
        png_ptr = nil
        info_ptr = nil
        
        
    }
    
    //When this function is called the row has already been completely processed and the 'row' and 'pass' refer to the next row to be handled.  For the non-interlaced case the row that was just handled is simply one less than the passed in row number, and pass will always be 0.


    

}


