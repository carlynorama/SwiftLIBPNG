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
    public static func pngData(for pixelData:inout [UInt8], width:UInt32, height:UInt32, bitDepth:BitDepth, colorType:ColorType) throws -> Data? {
        
        precondition(colorType != .palletized) //cannot handle that yet.

        guard let ihdr = try? IHDR(width: width, height: height, bitDepth: bitDepth, colorType: colorType) else {
            throw PNGError("pngData:Could not make IHDR")
        }
        
        let builder = LIBPNGDataBuilder(ihdr: ihdr)
        
        try builder?.appendTextChunk(keyword: "Comment", value: "Hello")
        try builder?.appendTextChunk(keyword: "Author", value: "Alice The Explorer")
        builder?.setTextChunks()
        
        try builder?.setIDAT(pixelData: pixelData, width: width, height: height)
        
       
        
        
        try builder?.writeData()
        
        
        
        return builder?.currentData()
    }
}
