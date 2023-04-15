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

void pngb_set_default_data_write_exit(png_structpp png_ptrp, png_infopp info_ptrp) {
    if (setjmp(png_jmpbuf(*png_ptrp))) {
        printf("png_for_swift: I'm outta here, %p, %p, %p, %p\n", png_ptrp, info_ptrp, *png_ptrp, *info_ptrp);
        //Have to destroy back in Swift code b/c something hinky with the pointer (especially info).
        //png_destroy_write_struct(png_ptrp, info_ptrp);
        return 2;
    }
}
