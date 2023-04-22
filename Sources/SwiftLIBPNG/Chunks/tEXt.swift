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

import Foundation
import png


//ContiguousArray<CChar>//<- This tells you what a Swift String is not.
// - not contiguous.
// - not chars.

extension SwiftLIBPNG {
    
    //Right now can only do English
    struct tEXt {
        let compression:ForLibPNG
        //when these get saved as Strings can fool you into thinking its working
        //but halfway through your string it's all like "byeeeee!" or "\uhqh389\j884fjf HAHAHA"
        let key:ContiguousArray<CChar>
        let value:ContiguousArray<CChar>
        let text_length:Int
        let key_length:Int
        
        
        init(key:String, value: String, compression:Int32 = PNG_TEXT_COMPRESSION_NONE) {
            precondition(key.count <= 79) //really should check C string, but fine for now.
            self.compression = compression
            self.key = key.utf8CString
            self.value = value.utf8CString
            self.text_length = self.value.count //- 1 //TODO: Check this
            self.key_length = self.key.count// - 1
            
            print(self.key)
            print(self.value)
        }
    }
}
