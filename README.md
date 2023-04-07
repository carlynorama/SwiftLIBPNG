# SwiftLIBPNG

A lightweight wrapper around `libpng` done to learn the process of wrapping an external C library. For information on how this library was made and other "how to get it to compile" info see [META.md](META.md)

So far, it compiles fine for MacOS 13+ (Swift 5.7, Xcode 14) using both Intel and M1 hardware with `libpng` installed via homebrew. 

## Alternatives of Note

If using a libpng library to avoid Apple-Hardware dependencies, consider a Package that is all Swift, no C, no Foundation. As of 2023 APR these two had fairly recent activity. 

- https://github.com/tayloraswift/swift-png
- https://swiftpackageindex.com/rbruinier/SwiftMicroPNG

## Resources

### About libpng

- <http://www.libpng.org>
- <http://www.libpng.org/pub/png/book/>
- more up to date than /book/ -> <http://www.libpng.org/pub/png/libpng-manual.txt> 
- had information that I did not find in manual. Actually has code post v1.6 -><https://github.com/glennrp/libpng/blob/12222e6fbdc90523be77633ed430144cfee22772/INSTALL> 

### Inspecting Data

To just look at the HEX

- <https://hexed.it>
- VSCode plugin Microsoft Hex Editor 
- Shell option 1 `od -t x1 png-transparent.png`
- Shell option 2 for bigger files `tail -f png-transparent.png | hexdump -C`

Very handy PNG verifier: <https://www.nayuki.io/page/png-file-chunk-inspector>


## Notes

- TODO: Write comparison of approaches

```c
    png_structp png_ptr = png_create_write_struct
       (PNG_LIBPNG_VER_STRING, (png_voidp)user_error_ptr,
        user_error_fn, user_warning_fn);
    png_structp png_ptr = png_create_write_struct_2
       (PNG_LIBPNG_VER_STRING, (png_voidp)user_error_ptr,
        user_error_fn, user_warning_fn, (png_voidp)
        user_mem_ptr, user_malloc_fn, user_free_fn);
```

- TODO: Case of the disappearing setjmp(png_jmpbuf(png_ptr))
