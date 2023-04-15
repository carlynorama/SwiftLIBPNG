//
//  png_for_swift.h
//  
//
//  Created by Carlyn Maw on 4/13/23.
//

#ifndef png_for_swift_h
#define png_for_swift_h

#include <stdio.h>
#include <png.h>

int pngb_version();

//NOPE. Total glitch fest.
//void pngb_set_default_data_write_exit(png_structpp png_ptrp, png_infopp info_ptrp);

//MARK: Writing and Setting

//Non IDAT-Chunks
int pngb_set_IHDR(png_structp png_ptr, png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth, int color_type, int interlace_method, int compression_method, int filter_method);

//IDAT
int pngb_set_rows(png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers);

//Pushing to IO
int pngb_write_png(png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params);


#endif /* png_for_swift_h */
