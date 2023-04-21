//
//  SwiftLIBPNG+ThrowingData.swift
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
    public static func pngData(for pixelData:inout [UInt8], width:UInt32, height:UInt32, bitDepth:BitDepth, colorType:ColorType) throws -> Data {
        
        precondition(colorType != .palletized) //cannot handle that yet.
        
        guard let ihdr = try? IHDR(width: width, height: height, bitDepth: bitDepth, colorType: colorType) else {
            throw PNGError("pngData:Could not make IHDR")
        }
        
        print("try builder")
        guard let builder = LIBPNGDataBuilder(ihdr: ihdr) else {
            throw PNGError("pngData:Could not make libpng png struct.")
        }
        
        print("try idat")
      
        
        try builder.setIDAT(pixelData: &pixelData, width: width, height: height)
        

        return builder.currentData()
    }
    
    final class LIBPNGDataBuilder {
        //libpng functions need these to be optional.
        //can force unwrap pointers in local code b/c if they are ever nil
        //there is a much bigger problem.
        private var _ptr: png_structp?
        private var _infoPtr: png_infop?
        private var _data: Data
        
        //Really should force component initialization with init.
        public init?(ihdr:IHDR) {
            let png_optr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
            if png_optr == nil { return nil }
            self._ptr = png_optr.unsafelyUnwrapped
            
            
            let info_optr = png_create_info_struct(png_optr);
            if info_optr == nil {
                png_destroy_write_struct(&_ptr, &_infoPtr)
                return nil
            }
            self._infoPtr = info_optr.unsafelyUnwrapped
            
            self._data = Data()
            
            let result = pngb_set_write_fn(_ptr!, &(self._data), writeDataCallback, nil)
            if result != 0 {
                png_destroy_write_struct(&_ptr, &_infoPtr)
                return nil
            }
            
            //libpng provides accessor function to IHDR info.
            //libpng should be the source of truth.
            do {
                try SwiftLIBPNG.setIHDR(png_ptr: _ptr!, info_ptr: _infoPtr!, width: ihdr.width, height: ihdr.height, bitDepth: ihdr.bitDepth.rawValue, colorType: ihdr.colorType.rawValue)
            } catch {
                png_destroy_write_struct(&_ptr, &_infoPtr)
                return nil
            }
        }
        
        func setIDAT(pixelData:inout [UInt8], width:UInt32, height:UInt32) throws {
            try pixelData.withUnsafeMutableBufferPointer{ pd_pointer in
                var row_pointers:[Optional<UnsafeMutablePointer<UInt8>>] = []
                for rowIndex in 0..<height {
                    let rowStart = rowIndex * width * 4
                    row_pointers.append(pd_pointer.baseAddress! + Int(rowStart))
                }
                
                try setRows(png_ptr: _ptr, info_ptr: _infoPtr, rowPointers: &row_pointers)
                try pushPNGData(png_ptr: _ptr, info_ptr: _infoPtr, transforms: PNG_TRANSFORM_IDENTITY, params: nil)
            }
        }
        
        func currentData() -> Data {
            return _data
        }
        
        
        deinit {
            png_destroy_write_struct(&_ptr, &_infoPtr)
        }
        
    }
}
