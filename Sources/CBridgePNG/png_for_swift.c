//
//  png_for_swift.c
//  
//
//  Created by Carlyn Maw on 4/13/23.
//

#include <stdlib.h>
#include <png.h>
#include "png_for_swift.h"

//TOO GLITCHY do not use. 
//void pngb_set_default_data_write_exit(png_structpp png_ptrp, png_infopp info_ptrp) {
//    if (setjmp(png_jmpbuf(*png_ptrp))) {
//        printf("png_for_swift: I'm outta here, %p, %p, %p, %p\n", png_ptrp, info_ptrp, *png_ptrp, *info_ptrp);
//        //Have to destroy back in Swift code b/c something hinky with the pointer (especially info).
//        //png_destroy_write_struct(png_ptrp, info_ptrp);
//        return 2;
//    }
//}

int pngb_set_IHDR(png_structp png_ptr, png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth, int color_type, int interlace_method, int compression_method, int filter_method) {
    
    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_write_struct(&png_ptr, &info_ptr);
        return 2;
    }
    
    png_set_IHDR(png_ptr, info_ptr, width, height, bit_depth, color_type, interlace_method, compression_method, filter_method);
    
    return 0;
}

int pngb_set_rows(png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers) {
    
    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("set rows error");
        png_destroy_write_struct(&png_ptr, &info_ptr);
        return 3;
    }
    
    png_set_rows(png_ptr, info_ptr, row_pointers);
    return 0;
}

int pngb_write_png(png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params) {
    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("write_png error");
        png_destroy_write_struct(&png_ptr, &info_ptr);
        return 4;
    }
    png_write_png(png_ptr, info_ptr, transforms, params);
}
