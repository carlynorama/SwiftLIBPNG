//
//  SwiftLIBPNG+ThrowingData.swift
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
    public static func pngData(for pixelData:[UInt8], width:UInt32, height:UInt32, bitDepth:BitDepth, colorType:ColorType, metaInfo:Dictionary<String, String>? = nil) throws -> Data? {
        
        precondition(colorType != .palletized) //cannot handle that yet.

        guard let ihdr = try? IHDR(width: width, height: height, bitDepth: bitDepth, colorType: colorType) else {
            throw PNGError("pngData:Could not make IHDR")
        }
        
        let builder = LIBPNGDataBuilder(ihdr: ihdr)
        
        if let metaInfo {
            for message in metaInfo {
                builder?.appendTextChunk(keyword: message.key, value: message.value)
            }
        }
        try builder?.setTextChunks()
        try builder?.setIDAT(pixelData: pixelData, width: width, height: height)
        try builder?.writeData()
        return builder?.currentData()
    }
}
