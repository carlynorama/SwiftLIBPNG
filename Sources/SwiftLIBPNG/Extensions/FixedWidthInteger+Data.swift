//
//  FixedWidthInteger+Data.swift
//  PNGScratchPad
//
//  Created by Carlyn Maw on 4/6/23.
//

import Foundation


extension FixedWidthInteger {
    
    var dataBigEndian: Data {
        var int = self.bigEndian
        return Data(bytes: &int, count: MemoryLayout<Self>.size)
    }
    
    var dataLittleEndian: Data {
        var int = self.littleEndian
        return Data(bytes: &int, count: MemoryLayout<Self>.size)
    }
}
