//
//  PNGErrors.swift
//  
//
//  Created by Carlyn Maw on 4/7/23.
//



enum PNGError: Error, CustomStringConvertible {
    case message(String)
    case outOfMemory
    case badBitDepth(SwiftLIBPNG.BitDepth, SwiftLIBPNG.ColorType)
    
    public var description: String {
        switch self {
        case let .message(message): return message
        case .outOfMemory:
            return "Out of Memory"
        case let .badBitDepth(bd, ct):
            return "BitDepth and ColorType miss-match \(bd), \(ct)"
        }
    }
    init(_ message: String) {
        self = .message(message)
    }
    
    init(_ code: CInt) {
        switch code {
        case 4:
            self = .outOfMemory
        case 2:
            self = .message("png returned 2")
        default:
            print("png code: \(code)")
            self = .message("Unknown PNG Error with code \(code)")
        }
    }
}
