//
//  File.swift
//  
//
//  Created by Carlyn Maw on 4/6/23.
//

import Foundation


//The chunk type is possibly the most unusual feature. It is specified as a sequence of binary values, which just happen to correspond to the upper- and lowercase ASCII letters used on virtually every computer in the Western, non-mainframe world. Since it is far more convenient (and readable) to speak in terms of text characters than numerical sequences, the remainder of this book will adopt the convention of referring to chunks by their ASCII names. Programmers of EBCDIC-based computers should take note of this and remember to use only the numerical values corresponding to the ASCII characters.
//
//Chunk types (or names) are usually mnemonic, as in the case of the IHDR or image header chunk. In addition, however, each character in the name encodes a single bit of information that shows up in the capitalization of the character.[56] Thus IHDR and iHDR are two completely different chunk types, and a decoder that encounters an unrecognized chunk can nevertheless infer useful things about it. From left to right, the four extra bits are interpreted as follows:
//[56] The ASCII character set was conveniently designed so that the case of a letter is always determined by bit 5. To put it another way, adding 32 to an uppercase character code gives you the code for its lowercase version.
//The first character's case bit indicates whether the chunk is critical (uppercase) or ancillary; a decoder that doesn't recognize the chunk type can ignore it if it is ancillary, but it must warn the user that it cannot correctly display the image if it encounters an unknown critical chunk. The tEXt chunk, covered in Chapter 11, "PNG Options and Extensions", is an example of an ancillary chunk.
//The second character indicates whether the chunk is public (uppercase) or private. Public chunks are those defined in the specification or registered as official, special-purpose types. But a company may wish to encode its own, application-specific information in a PNG file, and private chunks are one way to do that.
//The case bit of the third character is reserved for use by future versions of the PNG specification. It must be uppercase for PNG 1.0 and 1.1 files, but a decoder encountering an unknown chunk with a lowercase third character should deal with it as with any other unknown chunk.
//The last character's case bit is intended for image editors rather than simple viewers or other decoders. It indicates whether an editing program encountering an unknown ancillary chunk[57] can safely copy it into the new file (lowercase) or not (uppercase). If an unknown chunk is marked unsafe to copy, then it depends on the image data in some way. It must be omitted from the new image if any critical chunks have been modified in any way, including the addition of new ones or the reordering or deletion of existing ones. Note that if the program recognizes the chunk, it may choose to modify it appropriately and then copy it to the new file. Also note that unsafe-to-copy chunks may be copied to the new file if only ancillary chunks have been modified--again, including addition, deletion, and reordering--which implies that ancillary chunks cannot depend on other ancillary chunks.
//[57] Since any decoder encountering an unknown critical chunk has no idea how the chunk modifies the image--only that it does so in a critical way--an editor cannot safely copy or omit the chunk in the new image.
public enum ChunkType {
    case idhr

    var code:UInt32 {
        switch self {

        case .idhr:
            return FourCharCode(stringLiteral: "IDHR")
        }
    }
}


public struct PNGChunk {
    //4-byte length (in ``big-endian'' format, as with all integer values in PNG streams)/
    let type:ChunkType
    let data:[UInt8]
    let crc:UInt32

    //The length field refers to the length of the data field alone, not the chunk type or CRC.
    var length:UInt32 {
        UInt32(data.count)
    }

    var lengthBE:UInt32 {
        length.bigEndian
    }
}


extension FourCharCode: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        if let data = value.data(using: .macOSRoman), data.count == 4 {
            self = data.reduce(0, {$0 << 8 + Self($1)})
        } else {
            self = 0
        }
    }
   
}

public extension UInt32 {
    var string: String {
        String([
            Character(Unicode.Scalar(self >> 24 & 0xFF) ?? "?"),
            Character(Unicode.Scalar(self >> 16 & 0xFF) ?? "?"),
            Character(Unicode.Scalar(self >> 8 & 0xFF) ?? "?"),
            Character(Unicode.Scalar(self & 0xFF) ?? "?")
        ])
    }
}
