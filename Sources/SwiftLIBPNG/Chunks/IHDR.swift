//
//  IHDR.swift
//  
//
//  Created by Carlyn Maw on 4/21/23.
//  http://www.libpng.org/pub/png/spec/iso/index-object.html#11IHDR

import Foundation
import png


extension SwiftLIBPNG {
    //Note, libpng requires width & height to be UInt32
    struct IHDR {
        //(size in data chunk)
        let width:UInt32 //(4 bytes)
        let height:UInt32 //(4 bytes)
        let bitDepth:BitDepth //(1 byte)
        let colorType:ColorType //(1 byte)
        let compressionMethod:UInt8 = 0// (1 byte, value 0)
        let filterMethod:UInt8 = 0 // (1 byte, value 0)
        let interlaceMethod:UInt8 = 0 //(1 byte, values 0 "no interlace" or 1 "Adam7 interlace")
        
        init(width: UInt32, height: UInt32, bitDepth: BitDepth, colorType: ColorType) throws {
            guard colorType.allowedBitDepths.contains(bitDepth.rawValue) else {
                throw PNGError.badBitDepth(bitDepth, colorType)
            }
            self.width = width
            self.height = height
            self.bitDepth = bitDepth
            self.colorType = colorType
        }
    }
    
    
}

extension SwiftLIBPNG {
    
    public enum BitDepth:ForLibPNG {
        case one = 1
        case two = 2
        case four = 4
        case eight = 8
        case sixteen = 16
    }
    
}


extension SwiftLIBPNG {
    
    public enum ColorType:ForLibPNG {
        //values of
        //isPalette (bit 1, right most),
        //isTrichromatic (bit 2, center),
        //hasAlpha (bit 3, left most)
        
        case palletized = 0b011//requires PLTE chunk, plus optional tRNS chunk
        case truecolor  = 0b010 //optional tRNS chunk
        case grayscale = 0b000 //optional tRNS chunk
        case truecolorA = 0b110
        case grayscaleA = 0b100
        
        
        
        //incase want to do error checking.
        var allowedBitDepths:[ForLibPNG] {
            switch self {
            case .palletized:
                return [1, 2, 4, 8]
            case .truecolor:
                return [8, 16]
            case .grayscale:
                return [1, 2, 4, 8, 16]
            case .truecolorA:
                return [8, 16]
            case .grayscaleA:
                return [8, 16]
            }
        }
        
        
        func channelCount(bitDepth: UInt32) -> UInt32 {
            switch self {
            case .palletized:
                return 1
            case .truecolor:
                return 3
            case .grayscale:
                return 1
            case .truecolorA:
                return 4
            case .grayscaleA:
                return 2
            }
        }
    }
}


//extension SwiftLIBPNG.ColorTypes {
//    init?(colorTypeCode:UInt32) {
//        //precondition([0, 2, 3, 4,6].contains(colorTypeCode))
//        //values of
//        //isPalette (bit 1, right most),
//        //isTrichromatic (bit 2, center),
//        //hasAlpha (bit 3, left most)
//        switch colorTypeCode {
//        case 0b000:
//            self = .grayscale
//        case 0b010:
//            self = .truecolor
//        case 0b011:
//            self = .palletized
//        case 0b100:
//            self = .grayscaleA
//        case 0b110:
//            self = .truecolorA
//        default:
//            return nil
//        }
//    }
//}
