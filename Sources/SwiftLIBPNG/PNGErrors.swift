//
//  File.swift
//  
//
//  Created by Carlyn Maw on 4/7/23.
//

import Foundation


enum PNGError: Error, CustomStringConvertible {
    case message(String)
    case outOfMemory
    
    public var description: String {
        switch self {
        case let .message(message): return message
        case .outOfMemory:
            return "Out of Memory"
        }
    }
    init(_ message: String) {
        self = .message(message)
    }
}
