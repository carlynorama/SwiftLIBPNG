//
//  tEXt.swift
//  
//
//  Created by Carlyn Maw on 4/21/23.
//

//    The following keywords are predefined and should be used where appropriate.
//    Title     Short (one line) title or caption for image
//    Author     Name of image's creator
//    Description     Description of image (possibly long)
//    Copyright     Copyright notice
//    Creation Time     Time of original image creation
//    Software     Software used to create the image
//    Disclaimer     Legal disclaimer
//    Warning     Warning of nature of content
//    Source     Device used to create the image
//    Comment     Miscellaneous comment
//
// http://www.libpng.org/pub/png/spec/iso/index-object.html#11textinfo


import Foundation
import png


extension SwiftLIBPNG {
    
    //Right now can only do English
    struct tEXt {
        let compression:ForLibPNG

        
        //must be between 1 and 79 characters
        let key:ContiguousArray<CChar>
        //TODO: if length over x chars use different compression. (zTXt)
        let value:ContiguousArray<CChar>
        
        let text_length:Int
        let key_length:Int
        
        
        init(key:String, value: String, compression:Int32 = PNG_TEXT_COMPRESSION_NONE) {
             //really should check C string, but fine for now.
            self.compression = compression
            let CKey = key.utf8CString
            precondition((1...79).contains(CKey.count))
            self.key = CKey
            self.value = value.utf8CString
            self.text_length = self.value.count
            self.key_length = self.key.count
            
            print(self.key)
            print(self.value)
        }
    }
}
