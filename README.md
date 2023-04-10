# SwiftLIBPNG

A lightweight wrapper around `libpng` done to learn the process of wrapping an external C library. For information on how this library was made and other "how to get it to compile" info see [META.md](META.md)

So far, it compiles fine for MacOS 13+ (Swift 5.7, Xcode 14) using both Intel and M1 hardware with `libpng` installed via homebrew. 

## Alternatives of Note

If using a libpng library to avoid Apple-Hardware dependencies, also consider a Package that is all Swift, no C, no Foundation? As of 2023 APR these two had fairly recent activity. 

- <https://github.com/tayloraswift/swift-png>
- <https://swiftpackageindex.com/rbruinier/SwiftMicroPNG>

## Resources

### About libpng

Although some people will tell you that PNG stands for Portable Network Graphic, that is not the original meaning. The recursive pun "PNG Not Gif" is how it started. The official documentation is riddled with the same humor and very deep knowledge about how computers, color and people work. Still worth a read. 

- The main site: <http://www.libpng.org>
- How PNGs work. Code is out of date but still very much a good read: <http://www.libpng.org/pub/png/book/> 
- More up to date than /book/ but still seems to lag :<http://www.libpng.org/pub/png/libpng-manual.txt> 
- Actual most recent: https://github.com/glennrp/libpng/

- 'just the spec ma'am' - <https://www.w3.org/TR/2003/REC-PNG-20031110/>, <https://w3c.github.io/PNG-spec/>
- zlib spec for analyzing IDAT <https://www.zlib.net/manual.html>

### Inspecting Data

To just look at the HEX

- <https://hexed.it>
- VSCode plugin Microsoft Hex Editor 
- Shell option 1 `od -t x1 png-transparent.png`
- Shell option 2 for bigger files `tail -f png-transparent.png | hexdump -C`

Testing and verification

- Very handy PNG verifier: <https://www.nayuki.io/page/png-file-chunk-inspector>
- "The "official" test-suite for PNG" <http://www.schaik.com/pngsuite/>


## Notes

### Managing the pointers

To use `libpng` to read or write the first step is to allocate memory for structs `libpng` will use to store information about the png and its settings. 

From the documentation (on how to read, but a png_ptr and info_ptr are used for both reading a writing):

>The struct at which png_ptr points is used internally by libpng to keep track of the current state of the PNG image at any given moment; info_ptr is used to indicate what its state will be after all of the user-requested transformations are performed. One can also allocate a second information struct, usually referenced via an end_ptr variable; this can be used to hold all of the PNG chunk information that comes after the image data, in case it is important to keep pre- and post-IDAT information separate (as in an image editor, which should preserve as much of the existing PNG structure as possible). For this application, we don't care where the chunk information comes from, so we will forego the end_ptr information struct and direct everything to info_ptr.

The functions `libpng` provides for this come in two flavors, ones that return pointers and ones that take them and their handling functions in: 

```c
    png_structp png_ptr = png_create_write_struct(
        PNG_LIBPNG_VER_STRING,
        (png_voidp)user_error_ptr, 
        user_error_fn, 
        user_warning_fn
    );
    png_structp png_ptr = png_create_write_struct_2(
        PNG_LIBPNG_VER_STRING, 
            (png_voidp)user_error_ptr,
            user_error_fn, 
            user_warning_fn, 
            (png_voidp)
            user_mem_ptr, 
            user_malloc_fn, 
            user_free_fn
    );
```

Both styles of struct creation still require a call to `png_destroy_write_structs` functions on wrap up. Memory management is a big deal in C. Always write the destroy with the create, like closing a parens. 

### Most of the example code has a set_jmp? Why not yours?

A lot of example code has a chunk along the lines of: `if (setjmp(png_jmpbuf(png_ptr))) { /* DO THIS */ }`.

This overrides the default error handling if the file received is not a PNG file, for example. The default behaviors seem to be print statements and PNG_ABORT, from what I can tell, so it would be good to override them. However, using setjmp() and longjmp() to do that is not guaranteed to be thread safe. There is some ambiguity in the documentation (to me), but it seems as if the compiler flag to allow the setting of jumpdef is on by default because the newish "Simplified API" needs it. (It appears it was off by default in 1.4, but now is on again). Some implementations on libpng turn it off.

Why hassle with this very C specific type of error handling? The setjmp saves the calling environment to be used by longjmp. This means inside the setjmp block using png_ptr, info_ptr, or even returning will all work. C callbacks, by contrast, can only use what get offered to them as parameters. 

Look in example code for
- `PNG_SETJMP_NOT_SUPPORTED` in older code 
- `#define PNG_NO_SETJMP` turns the feature off `#define PNG_SETJMP_SUPPORTED` turns the feature on)
- Also might be `#undef PNG_SETJMP_SUPPORTED`
- `#include <setjmp.h>` is an indicator the code will be using `png_jmpbuf` style error setting
        
For more information on libpng and setjmp/longjmp: 
- search for "Setjmp/longjmp issues" [INSTALL guide](https://github.com/glennrp/libpng/blob/12222e6fbdc90523be77633ed430144cfee22772/INSTALL) 
- Also:[example.c]( https://github.com/glennrp/libpng/blob/a37d4836519517bdce6cb9d956092321eca3e73b/example.c)
- search for "Error handling in libpng is done through"  in [the manual](https://github.com/glennrp/libpng/blob/libpng16/libpng-manual.txt)

For more on setjmp/longjmp in general:
- https://en.wikipedia.org/wiki/Setjmp.h
- https://web.eecs.utk.edu/~huangj/cs360/360/notes/Setjmp/lecture.html
- https://stackoverflow.com/questions/1692814/exception-handling-in-c-what-is-the-use-of-setjmp-returning-0
- https://stackoverflow.com/questions/14685406/practical-usage-of-setjmp-and-longjmp-in-c
- https://stackoverflow.com/questions/7334595/longjmp-out-of-signal-handler
- https://tratt.net/laurie/blog/2005/timing_setjmp_and_the_joy_of_standards.html

That said, to side step all of that (while still getting more graceful failing behavior?) the choices appear to be 
-  Using those aforementioned "Simplified libpng API" (No examples of that in this repo) 
-  Setting the error functions in the `png_create_*_struct` functions, i.e.  `(png_voidp)user_error_ptr, user_error_fn, user_warning_fn)`, although hardly any examples use that. 

#### Custom Error Functions

From the manual, the warning functions passes to `png_create_*_struct` should be of the formats:
```c
    void user_error_fn(png_structp png_ptr,
        png_const_charp error_msg);

    void user_warning_fn(png_structp png_ptr,
        png_const_charp warning_msg);

//Then, within your user_error_fn or user_warning_fn, you can retrieve
//the error_ptr if you need it, by calling

    png_voidp error_ptr = png_get_error_ptr(png_ptr);
```

After initialization `png_set_error_fn` can be used after struct init to update what error function should be used.

For an idea of the type of strings the `error_fn` and `warning_fn` try browsing the results of a [search for png_error](https://github.com/glennrp/libpng/search?q=png_error&type=code) or [png_warning](https://github.com/glennrp/libpng/search?q=png_warning&type=code) in the libpng github repo. 

Examples:
        - https://github.com/glennrp/libpng/blob/a37d4836519517bdce6cb9d956092321eca3e73b/contrib/visupng/PngFile.c
        - https://github.com/glennrp/libpng/blob/5f5f98a1a919e89f0bcea26d73d96dec760f222f/contrib/libtests/timepng.c
        - https://github.com/glennrp/libpng/blob/61bfdb0cb02a6f3a62c929dbc9e832894c0a8df2/contrib/libtests/pngvalid.c
        - https://github.com/glennrp/libpng/blob/a37d4836519517bdce6cb9d956092321eca3e73b/contrib/gregbook/writepng.c

The addition of an ErrorPointer struct that could hold needed information to pass the the error function can help with clean up. The error_ptr is a `void*`, as long as YOU know what it is, it can be whatever you need.
    
If the user will just leave the program at this point missing a dealloc may not the biggest deal, but file IO and network might not be closed, so be sure to check. 
    
If your callback nopes out with an `exit` or `abort`, this "Quitting behavior" will prevent being accepted into the app store. That's also no better than libpng default, so almost might as well have left it nil.

the `buildSimpleDataExample` calls a working, but not super useful, callback example.

### Why in my PNG file do I not see the pixel data I'm expecting?

- TODO: write about filter types
http://www.libpng.org/pub/png/book/chapter09.html
 None     Each byte is unchanged.
 Sub     Each byte is replaced with the difference between it and the ``corresponding byte'' to its left.
 Up     Each byte is replaced with the difference between it and the byte above it (in the previous row, as it was before filtering).
 Average     Each byte is replaced with the difference between it and the average of the corresponding bytes to its left and above it, truncating any fractional part.
 Paeth     Each byte is replaced with the difference between it and the Paeth predictor of the corresponding bytes to its left, above it, and to its upper left.

### Why does the writing example use Data instead of [UInt8]?

When trying to write cross-platform code, I tend to try to use the lowest level type as much as possible to move information around. In this case using a `[UInt8]` over a `Data` would cost so much additional overhead, it's not currently worth the hassle. 

The `UnsafeMutableRawPointer` pointer returned from `png_get_io_ptr` always points to the data structure's head, whether a file or Data, or something else, not to a cursor location where new Data should be written to. If the `buildSimpleDataExample` function and it's `writeDataCallback` callback were embedded in a class, then one could potentially make a class variable that holds "whats my IO curser offset?" information for the callback function to refer to. 

But `buildSimpleDataExample` is not in a class or even a struct instance! So what is a lone little static function to do? 

The good news is that `Data` is magic. `Data` (unlike say `[UInt8]`) has [private size variables allocated with it](https://github.com/apple/swift-corelibs-foundation/blob/eec4b26deee34edb7664ddd9c1222492a399d122/Sources/Foundation/Data.swift). This means it can implement `func append(_ bytes: UnsafeRawPointer, length: Int)`

```swift
    @inlinable // This is @inlinable as it does not escape the _DataStorage boundary layer.
    func append(_ bytes: UnsafeRawPointer, length: Int) {
        precondition(length >= 0, "Length of appending bytes must not be negative")
        let origLength = _length
        let newLength = origLength + length
        if _capacity < newLength || _bytes == nil {
            ensureUniqueBufferReference(growingTo: newLength, clear: false)
        }
        _length = newLength
        __DataStorage.move(_bytes!.advanced(by: origLength), bytes, length)
    }
```

The existence of this function means we can append when all we have is a pointer. It's amazing. 

The [example C code](https://stackoverflow.com/questions/1821806/how-to-encode-png-to-buffer-using-libpng)  floating around the internet for writing to a buffer is:

```c
//Make a new compound type that stores the pointer and the cursor location/size
struct mem_encode
{
  char *buffer;
  size_t size;
}
void my_png_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
  /* with libpng15 next line causes pointer deference error; use libpng12 */
  struct mem_encode* p=(struct mem_encode*)png_get_io_ptr(png_ptr); /* was png_ptr->io_ptr */
  size_t nsize = p->size + length;

  /* allocate or grow buffer */
  if(p->buffer)
    p->buffer = realloc(p->buffer, nsize);
  else
    p->buffer = malloc(nsize);

  if(!p->buffer)
    png_error(png_ptr, "Write Error");

  /* copy new bytes to end of buffer */
  memcpy(p->buffer + p->size, data, length);
  p->size += length;
}
```

Where you can see that it is implementing by hand that buffer tracking (`mem_encode`) and the buffer expansion by hand.

Thankfully using `Data` appears to make all of that unnecessary.  

### Simplified API

//TODO: Learn about this.

A "simplified API" has been added (see documentation in png.h and a simple
example in contrib/examples/pngtopng.c).  The new publicly visible API
includes the following:
```
   macros:
     PNG_FORMAT_*
     PNG_IMAGE_*
   structures:
     png_control
     png_image
   read functions
     png_image_begin_read_from_file()
     png_image_begin_read_from_stdio()
     png_image_begin_read_from_memory()
     png_image_finish_read()
     png_image_free()
   write functions
     png_image_write_to_file()
     png_image_write_to_memory()
     png_image_write_to_stdio()
```
