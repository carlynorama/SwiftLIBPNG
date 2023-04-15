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
int pngb_test_error_fetching();

void pngb_set_default_data_write_exit(png_structp png_ptr, png_infop info_ptr);
//void set_default_file_write_exit(png_structp png_ptr, png_infop info_ptr, png_FILE_p file_ptr);

#endif /* png_for_swift_h */
