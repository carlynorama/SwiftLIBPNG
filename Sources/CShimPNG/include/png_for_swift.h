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

//MARK: Writing and Setting

//Setting Callbacks
int pngshim_set_write_fn(png_structrp png_ptr, png_voidp io_ptr, png_rw_ptr write_data_fn, png_flush_ptr output_flush_fn);
//Non IDAT-Chunks
int pngshim_set_IHDR(png_structp png_ptr, png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth, int color_type, int interlace_method, int compression_method, int filter_method);

//IDAT
int pngshim_set_rows(png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers);

//Pushing to IO
int pngshim_write_png(png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params);

int pngshim_set_text(png_structp png_ptr, png_infop info_ptr, png_const_textp text_ptr, int num_text);


#endif /* png_for_swift_h */
