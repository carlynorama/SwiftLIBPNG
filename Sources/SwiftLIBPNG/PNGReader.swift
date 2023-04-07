//
//  File.swift
//  
//
//  Created by Carlyn Maw on 4/6/23.
//

import Foundation
import png

//http://www.libpng.org/pub/png/libpng-manual.txt

enum PNGError: Error, CustomStringConvertible {
    case message(String)
    case outOfMemory
    
    public var description: String {
        switch self {
        case let .message(message): return message
        case .outOfMemory:
            return "Out of Memory"
        }
    }
    init(_ message: String) {
        self = .message(message)
    }
}


//DOC: The struct at which png_ptr points is used internally by libpng to keep track of the current state of the PNG image at any given moment; info_ptr is used to indicate what its state will be after all of the user-requested transformations are performed. One can also allocate a second information struct, usually referenced via an end_ptr variable; this can be used to hold all of the PNG chunk information that comes after the image data, in case it is important to keep pre- and post-IDAT information separate (as in an image editor, which should preserve as much of the existing PNG structure as possible). For this application, we don't care where the chunk information comes from, so we will forego the end_ptr information struct and direct everything to info_ptr.

final public class PNGReader {
    //var fileURL:URL?
    var png_ptr:OpaquePointer?
    var info_ptr:OpaquePointer?
    //var endinfo_ptr:OpaquePointer?
    //public let path: String
    //fileprivate let file: UnsafeMutablePointer<FILE>!
    
    public init() {
    }
    
    deinit {
        destroy()
    }
    
    func destroy() {
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
    
    public func startRead(from url:URL) throws {
        print(url.relativePath)
        let file_ptr = fopen(url.relativePath, "r")
        if file_ptr == nil {
            throw PNGError("File pointer not available")
        }
        
        print("file handle")
        
        png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil,
                                         nil);
        //(PNG_LIBPNG_VER_STRING, (png_voidp)user_error_ptr,user_error_fn, user_warning_fn)
        
        if (png_ptr == nil) {
            throw PNGError.outOfMemory
        }
        
        info_ptr = png_create_info_struct(png_ptr);
        if (info_ptr == nil) {
            png_destroy_read_struct(&png_ptr, nil, nil);
            throw PNGError.outOfMemory;   /* out of memory */
        }
        
        //TODO: Why not working? Is it even needed?

        //possible alternate approach post 1.5
        //png_set_longjmp_fn
        //png_longjmp
        //png_longjmp_ptr = @convention(c) (UnsafeMutablePointer<Int32>?, Int32) -> Void
        
//        if (setjmp(png_jmpbuf(png_ptr))) {
//            png_destroy_read_struct(&png_ptr, &info_ptr, nil);
//            throw PNGError("2");
//        }
        
        //DOC: If you would rather avoid the complexity of setjmp/longjmp issues, you can compile libpng with PNG_NO_SETJMP, in which case
        //errors will result in a call to PNG_ABORT() which defaults to abort().
        //TODO: Yes, okay, how?
        
        png_init_io(png_ptr, file_ptr);
        
//        DOC: If you had previously opened the file and read any of the signature from the beginning in order to see if this was a PNG file, you need to let libpng know that there are some bytes missing from the start of the file.
//
//            png_set_sig_bytes(png_ptr, number);
        
        //TODO: CRC handling
        //png_set_crc_action(png_ptr, crit_action, ancil_action);
        
        png_set_read_status_fn(png_ptr, rowCompleteCallback);
        
        //ignore set gamma and set alpha for now
        
        //See documentaion full set of masks that can be applied
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
        
        
    }
    
    //When this function is called the row has already been completely processed and the 'row' and 'pass' refer to the next row to be handled.  For the non-interlaced case the row that was just handled is simply one less than the passed in row number, and pass will always be 0.
    let rowCompleteCallback:@convention(c) (OpaquePointer?, UInt32, Int32) -> () = {png_ptr, row, pass in
        print(png_ptr ?? "nil", row, pass)
    }

    
//    func longJumpFunction() throws {
//        png_destroy_read_struct(&png_ptr, &info_ptr, nil);
//        throw PNGError("2");
//    }
}
