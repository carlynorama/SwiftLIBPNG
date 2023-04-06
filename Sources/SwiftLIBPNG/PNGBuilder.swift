//
//  File.swift
//  
//
//  Created by Labtanza on 4/6/23.
//

import Foundation
import png


public class PNGBuilder {
    private var _ptr: OpaquePointer
    private var _infoPtr: OpaquePointer
    
    //Really should force component initialization with init.
    public init?() {
        //user_png_ver version string of the library. Must be PNG_LIBPNG_VER_STRING
        //error_ptr user defined struct for error functions.
        //error_fn user defined function for printing errors and aborting.
        //warn_fn user defined function for warnings.
        //this version of the function does the memory handling.
        let png_optr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if png_optr == nil { return nil }
        self._ptr = png_optr.unsafelyUnwrapped
        

        let info_optr = png_create_info_struct(png_optr);
        if info_optr == nil { return nil }
        self._infoPtr = info_optr.unsafelyUnwrapped
    }
    
    
//    public func setColor(red:UInt8, green:UInt8, blue:UInt8, alpha:UInt8) {
//        //C:-- void set_color_values(COpaqueColor* c, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
//        set_color_values(_ptr, red, green, blue, alpha)
//
//    }
//
//    deinit {
//        //C:-- void delete_pointer_for_ccolor() { //has free// }
//        //(see Note above.)
//        delete_pointer_for_ccolor(_ptr)
//    }
    
}


//TODO: Go the other way?
//let str0 = "boxcar" as CFString
//let bits = Unmanaged.passUnretained(str0)
//let ptr = bits.toOpaque()

