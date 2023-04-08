
//
//  SwiftLIBPNGData.swift
//
//  Created by Carlyn Maw on 4/6/23.
//

// Thank you https://hexed.it and VSCode plugin Microsoft Hex Editor but ultimately shell FTW.

//od -t x1 png-transparent.png
//tail -f png-transparent.png | hexdump -C

//Also: https://www.nayuki.io/page/png-file-chunk-inspector


extension SwiftLIBPNG {
    //These two items should be save-able as PNGs
    public static let small_transparent_full = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //file signature
                                              0x00, 0x00, 0x00, 0x0d, //size of IDHR (always 13)
                                              0x49, 0x48, 0x44, 0x52, //"IDHR"
                                              0x00, 0x00, 0x00, 0x01, //width - 1
                                              0x00, 0x00, 0x00, 0x01, //height - 1
                                                                0x08, //bit depth
                                                                0x06, //color type
                                                                0x00, //compression method
                                                                0x00, //filter method
                                                                0x00, //interlace method
                                              0x1f, 0x15, 0xc4, 0x89, //CRC-32 1F15C489
                                              //---------------- data chunk
                                              0x00, 0x00, 0x00, 0x0a, //size of IDAT - 10
                                              0x49, 0x44, 0x41, 0x54, //"IDAT"
                                                        
                                                          0x78, 0x9c, // zlib header?
                                              0x63, 0x00, 0x01, 0x00, //<- some how this all translates to "nothing to see here."
                                              0x00, 0x05, 0x00, 0x01, // ? Adler-32 check ?
                                                
                                              0x0d, 0x0a, 0x2d, 0xb4, //CRC-32 0D0A2DB4
                                              //---------------- end chunk
                                              0x00, 0x00, 0x00, 0x00, //size of IEND
                                              0x49, 0x45, 0x4e, 0x44, //"IEND"
                                              0xae, 0x42, 0x60, 0x82 //CRC-32 AE426082
                                             ]
    
    public static let small_rgba_full = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //file signature
                                       //---------------- header chunk
                                       0x00, 0x00, 0x00, 0x0d, //size of IDHR (always 12)
                                       0x49, 0x48, 0x44, 0x52, //"IHDR"
                                       0x00, 0x00, 0x00, 0x03, //width - 3
                                       0x00, 0x00, 0x00, 0x02, //height- 2
                                                         0x08, //bit depth
                                                         0x02, //color type
                                                         0x00, //compression method
                                                         0x00, //filter method
                                                         0x00, //interlace method
                                       0x12, 0x16, 0xf1, 0x4d, //CRC-32 1216F14D
                                       //---------------- data chunk
                                       0x00, 0x00, 0x00, 0x1f, //size of IDAT - 31
                                       0x49, 0x44, 0x41, 0x54, //"IDAT"
                                                   0x08, 0x1d, //zlib Header
                                                         0x01, //?? BFINAL = 1, BTYPE = 00 ?
                                       0x14, 0x00, 0xeb, 0xff, //LEN & NLEN of data  (Length of data -> 20 (3*3 + 2))
                                       
                                                         0x00, //row filter filter type (none/no change)
                                       0xff, 0x00, 0x00,       //No compression pixel 1
                                       0x00, 0xff, 0x00,       //No compression pixel 2
                                       0x00, 0x00, 0xff,       //No compression pixel 3
                                                         0x00, //row filter filter type (none/no change)
                                       0x00, 0x00, 0x00,       //No compression pixel 4
                                       0x80, 0x80, 0x80,       //No compression pixel 5
                                       0xff, 0xff, 0xff,       //No compression pixel 6
                                         
                                       0x3a, 0x61, 0x07, 0x7b, //Adler-32 check sum of uncompressed full image.
                                       //TODO: Adler-32 value per image - but is it transmitted with each chunk?
                                       0xcb, 0xca, 0x5c, 0x63, //CRC-32 CBCA5C63
                                       //---------------- end chunk
                                       0x00, 0x00, 0x00, 0x00, //size of IEND
                                       0x49, 0x45, 0x4e, 0x44, //"IEND"
                                       0xae, 0x42, 0x60, 0x82 //CRC-32 AE426082
                                      ]
    //

}
