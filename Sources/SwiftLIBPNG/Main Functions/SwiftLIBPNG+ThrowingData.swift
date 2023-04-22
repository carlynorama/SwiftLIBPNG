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
import CShimPNG

extension SwiftLIBPNG {
    public static func pngData(for pixelData:inout [UInt8], width:UInt32, height:UInt32, bitDepth:BitDepth, colorType:ColorType) throws -> Data? {
        
        precondition(colorType != .palletized) //cannot handle that yet.

        guard let ihdr = try? IHDR(width: width, height: height, bitDepth: bitDepth, colorType: colorType) else {
            throw PNGError("pngData:Could not make IHDR")
        }
        
        let builder = LIBPNGDataBuilder(ihdr: ihdr)
        
        try builder?.appendTextChunk(keyword: "Author", value: "ABCDEFGHIJKLMNO")//<- get a bit of corruption at the end here.
        try builder?.appendTextChunk(keyword: "Comment", value: "Hello")
        //as soon as add the O get the bad character warning.
        try builder?.appendTextChunk(keyword: "ABCDEFGHIJKLMN", value: "AliceTheExplorer")//<-doesn't work at all
        
        builder?.setTextChunks()
        
        try builder?.setIDAT(pixelData: pixelData, width: width, height: height)
        
       
        
        
        try builder?.writeData()
        
        
        
        return builder?.currentData()
    }
}
