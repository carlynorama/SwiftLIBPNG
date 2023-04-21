//
//  File.swift
//  
//
//  Created by Carlyn Maw on 4/21/23.
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
        return Data()
    }
}
