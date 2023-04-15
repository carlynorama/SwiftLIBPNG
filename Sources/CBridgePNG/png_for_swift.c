//
//  png_for_swift.c
//  
//
//  Created by Carlyn Maw on 4/13/23.
//

#include <stdlib.h>
#include <png.h>
//#include <setjmp.h>
#include "png_for_swift.h"



int pngb_test_error_fetching() {
    int number_of_errors = 4;
    return rand() % number_of_errors;
}

int pngb_version() {
    int version = png_access_version_number();
    printf("%d", version);
    return version;
}

void pngb_set_default_data_write_exit(png_structp png_ptr, png_infop info_ptr) {
    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_write_struct(&png_ptr, &info_ptr);
        printf("%s", "png_for_swift: I'm outta here");
        return 2;
    }
}
