//
//  File.swift
//  
//
//  Created by Carlyn Maw on 4/5/23.
//

import Foundation




enum ColorStorageStyle {
    case RGBA32   //[0]RR, [1]GG, [2]BB, [3]AA
    case ABGR32   //[0]AA, [1]BB, [2]GG, [3]RR
    
    
    var red_shift:Int { self == .ABGR32 ? 24 : 0 }
    var green_shift:Int { self == .ABGR32 ? 16 : 8 }
    var blue_shift:Int { self == .ABGR32 ? 8 : 16 }
    var alpha_shift:Int { self == .ABGR32 ? 0 : 24 }
}

@propertyWrapper struct Color32 {
    var wrappedValue: UInt32
    let storageStyle: ColorStorageStyle
    

    init(wrappedValue: UInt32, storageStyle:ColorStorageStyle = .ABGR32) {
        self.wrappedValue = wrappedValue
        self.storageStyle = storageStyle
    }
    
    public init(bytes:[UInt8], storageStyle:ColorStorageStyle = .ABGR32) {
        //var tmp = UInt32(bytes[0])
        //tmp += UInt32(bytes[1]) << 8
        //tmp += UInt32(bytes[2]) << 16
        //tmp += UInt32(bytes[3]) << 24
        self.wrappedValue = bytes.withUnsafeBytes { (bytesPtr) -> UInt32 in
            bytesPtr.load(as: UInt32.self)
        }
        self.storageStyle = storageStyle
    }
    
    public init(red:UInt8, green:UInt8, blue:UInt8, alpha:UInt8, storageStyle:ColorStorageStyle = .ABGR32) {
        self.storageStyle = storageStyle
        var tmp = UInt32(alpha) << self.storageStyle.alpha_shift
        tmp += UInt32(blue) << self.storageStyle.blue_shift
        tmp += UInt32(green) << self.storageStyle.green_shift
        tmp += UInt32(red) << self.storageStyle.red_shift
        self.wrappedValue = tmp
    }
    
    var asRGBA32:UInt32 {
        if storageStyle == .RGBA32 {
            return wrappedValue
        } else {
            return wrappedValue.byteSwapped
        }
    }
    
    var asABGR32:UInt32 {
        if storageStyle == .ABGR32 {
            return wrappedValue
        } else {
            return wrappedValue.byteSwapped
        }
    }
    

    
}
