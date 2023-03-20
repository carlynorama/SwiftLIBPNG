#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png

public struct SwiftLIBPNG {
    public private(set) var text = "Hello, World!"

    public init() {
    }

    public static func version() {
       let version = png_access_version_number()
       print(version)
    }
    
    public static func makeTestImage(width:UInt32, height:UInt32, red:UInt8, green:UInt8, blue:UInt8) {
        let bytes_per_row = width * 4 //4 bytes per pixel
        var rowData:[[UInt8]] = []
        rowData.reserveCapacity(Int(height))
        for rowNum in 0..<height {
            let alpha = UInt8(Double(rowNum)/Double(height) * 255.0)
            var row:[UInt8] = []
            row.reserveCapacity(Int(bytes_per_row))
            for _ in 0..<width {
                row.append(red)
                row.append(green)
                row.append(blue)
                row.append(alpha) //alpha
            }
            rowData.append(row)
        }
        
    }
    
    public static func makeImage(with rowData:[[UInt8]], width:UInt32, height:UInt32) -> Data? {
        //user_png_ver version string of the library. Must be PNG_LIBPNG_VER_STRING
        //error_ptr user defined struct for error functions.
        //error_fn user defined function for printing errors and aborting.
        //warn_fn user defined function for warnings.
        //this version of the function does the memory handling.
        let png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if png == nil { return nil }
        
        let info = png_create_info_struct(png);
        if info == nil { return nil }
        
        //TODO: Setup error handling
        
        //png_set_IHDR() shall set image header information in info_ptr. width is the image width in pixels. height is the image height in pixels. bit_depth is the bit depth of the image. Valid values shall include 1, 2, 4, 8, 16 and shall also depend on the color type. color_type is the type of image. Supported color types shall include: PNG_COLOR_TYPE_GRAY (bit depths 1, 2, 4, 8, 16) PNG_COLOR_TYPE_GRAY_ALPHA (bit depths 8, 16) PNG_COLOR_TYPE_PALETTE (bit depths 1, 2, 4, 8) PNG_COLOR_TYPE_RGB (bit depths 8, 16) PNG_COLOR_TYPE_RGB_ALPHA (bit depths 8, 16) PNG_COLOR_MASK_PALETTE PNG_COLOR_MASK_COLOR PNG_COLOR_MASK_ALPHA interlace_type is the image interlace method. Supported values shall include: PNG_INTERLACE_NONE or PNG_INTERLACE_ADAM7 compression_type is the method used for image compression. The value must be PNG_COMPRESSION_TYPE_DEFAULT. filter_type is the method used for image filtering. The value must be PNG_FILTER_TYPE_DEFAULT.
        png_set_IHDR(png,
                     info,
                     width,
                     height,
                     8,
                     PNG_COLOR_TYPE_RGB_ALPHA,
                     PNG_INTERLACE_NONE,
                     PNG_COMPRESSION_TYPE_DEFAULT,
                     PNG_FILTER_TYPE_DEFAULT);
        
        //png_write_info(png, info);
        
        
        
        var rowData:[[UInt8]] = []
        rowData.reserveCapacity(Int(height))
        for rowNum in 0..<height {
            let alpha = UInt8(Double(rowNum)/Double(height) * 255.0)
            var row:[UInt8] = []
            row.reserveCapacity(Int(bytes_per_row))
            for _ in 0..<width {
                row.append(red)
                row.append(green)
                row.append(blue)
                row.append(alpha) //alpha
            }
            rowData.append(row)
        }
        
        print(rowData)
        print(png)
        
        
        return "".data(using: .utf8)!
    }
    
    public static func verifyPNG(data:Data) -> Bool {
        false
    }
    
    

}
