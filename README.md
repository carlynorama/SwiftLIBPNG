# SwiftLIBPNG

A lightweight wrapper around `libpng` done to learn the process of wrapping an external C library. For information on how this library was made and other "how to get it to compile" info see [META.md](META.md)

So far, it compiles fine for MacOS 13+ (Swift 5.7, Xcode 14) using both Intel and M1 hardware with `libpng` installed via homebrew. 

## Alternatives of Note

If using a libpng library to avoid Apple-Hardware dependencies, also consider a Package that is all Swift, no C, no Foundation? As of 2023 APR these two had fairly recent activity. 

- https://github.com/tayloraswift/swift-png
- https://swiftpackageindex.com/rbruinier/SwiftMicroPNG

## Resources

### About libpng

Although some people will tell you that PNG stands for Portable Network Graphic, that is not the original meaning. The recursive pun "PNG Not Gif" is how it started. The official documentation is riddled with the same humor and very deep knowledge about how computers, color and people work. Still worth a read. 

- The main site: <http://www.libpng.org>
- How PNGs work. Code is out of date but still very much a good read: <http://www.libpng.org/pub/png/book/> 
- More up to date than /book/ but still seems to lag :<http://www.libpng.org/pub/png/libpng-manual.txt> 
- Had information that I did not find in manual. Actually has code post v1.6 -><https://github.com/glennrp/libpng/blob/12222e6fbdc90523be77633ed430144cfee22772/INSTALL> 

- 'just the spec ma'am' - https://www.w3.org/TR/2003/REC-PNG-20031110/
- zlib spec for analyzing IDAT https://www.zlib.net/manual.html

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

- TODO: filter types
http://www.libpng.org/pub/png/book/chapter09.html
 None     Each byte is unchanged.
 Sub     Each byte is replaced with the difference between it and the ``corresponding byte'' to its left.
 Up     Each byte is replaced with the difference between it and the byte above it (in the previous row, as it was before filtering).
 Average     Each byte is replaced with the difference between it and the average of the corresponding bytes to its left and above it, truncating any fractional part.
 Paeth     Each byte is replaced with the difference between it and the Paeth predictor of the corresponding bytes to its left, above it, and to its upper left.
