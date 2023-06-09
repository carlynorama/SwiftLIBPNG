# SwiftLIBPNG

A lightweight wrapper around `libpng` done to learn the process of wrapping an external C library. For information on how this library was made and other "how to get it to compile" info see [META.md](META.md)

So far, it compiles fine for:
 - MacOS 13+ (Swift 5.7, Xcode 14) using both Intel and M1 hardware with `libpng` installed via `homebrew`. 
 - Ubuntu 22.04 with Swift 5.8 installed, `libpng` installed via `apt install`

## Alternatives of Note

This package is a learning project, not a production product.

If searching for png library that isn't limited to Apple-Hardware dependencies, also consider a Package that is all Swift, no C, no Foundation? As of 2023 APR these two had fairly recent activity. 

- <https://github.com/tayloraswift/swift-png>
- <https://swiftpackageindex.com/rbruinier/SwiftMicroPNG>

## In this repo

In the source directory are 3 folders

- png: holds the modulemap for including libpng exclusively. See the [META.md](META.md) for more info. 
- CShimPNG: Some very small C wrapper functions to allow the libpng error handling to work with Swift style error handling. See the section in the Notes for more info.  (could be folded into `png` potentially)
- SwiftLIBPNG: The real target Swift API


### SwiftLIBPNG

SwiftLIBPNG offers static functions for the creation of PNG files. Each of those functions has a file in the "Main Functions" folder. 

#### SwiftLIBPNG+SimpleData

- `public static func optionalPNGDataForRGBA(width:UInt32, height:UInt32, pixelData:[UInt8]) -> Data?`

Non-throwing, but libpng will crash the program if there is a fatal error. Uses a function & required Data creation callback to create a Data blob with properly PNG data. Can then be used to save to a file with no changes. As an experiment, uses Swift error callback functions... to reproduce the same crashing behavior that libpng does.  

#### SwiftLIBPNG+SimpleReading

- `public static func simpleFileRead(from path:String) throws -> [UInt8]`

Throws, but only based on initial file missing/no memory errors. libpng will crash the program if there is a fatal error later. Uses a single function and optional current-status callback to open a file and return an uncompressed UInt8 array of pixel data. As currently written it is up to the user to know ahead of time what kind of data that will be, although the header information is printed to the console. 

#### SwiftLIBPNG+SimpleThrowingData

- `public static func pngForRGBA(for pixelData:[UInt8], width:UInt32, height:UInt32, bitDepth:UInt8 = 8)`

Like `optionalPNGForRGBAData`, a single function again. Instead of aborting or returning nil, it uses sub-functions defined in `CShimPNG` and `SwiftLIBPNG+Throwing` to make a program that doesn't crash, even when there is a fatal error caught by `libpng`.

#### SwiftLIBPNG+ThrowingData

- `public static func pngData(for pixelData:[UInt8], width:UInt32, height:UInt32, bitDepth:BitDepth, colorType:ColorType, metaInfo:Dictionary<String, String>? = nil) throws -> Data?`

Uses a `LIBPNGDataBuilder` class to reproduce `pngForRGBAData` for any non-palletized data pixel data. Adds uncompressed text info to PNG: User submitted, a "Creation Date" and "Software"

## Resources

### About libpng

Although some people will tell you that PNG stands for Portable Network Graphic, that is not the original meaning. The recursive pun "PNG Not Gif" is how it started. The official documentation is riddled with the same humor and very deep knowledge about how computers, color and people work. Still worth a read. 

- The main site: <http://www.libpng.org>
- How PNGs work. Code is out of date but still very much a good read: <http://www.libpng.org/pub/png/book/> 
- More up to date than /book/ but still seems to lag :<http://www.libpng.org/pub/png/libpng-manual.txt> 
- Actual most recent: https://github.com/glennrp/libpng/

- 'just the spec ma'am' 
    - <https://www.w3.org/TR/2003/REC-PNG-20031110/>
    - <https://w3c.github.io/PNG-spec/>
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

### Misc PNG info

- <https://pyokagan.name/blog/2019-10-14-png/>


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

### What's the deal with that extra CShimPNG Target?

A lot of libpng example code has a chunk along the lines of: `if (setjmp(png_jmpbuf(png_ptr))) { /* DO THIS */ }`.

This overrides the default error handling if the file received is not a PNG file, for example. The default behaviors seem to be print statements and PNG_ABORT, from what I can tell, so it would be good to override them. However, using setjmp() and longjmp() to do that is not guaranteed to be thread safe. There is some ambiguity in the documentation (to me), but it seems as if the compiler flag to allow the setting of jumpdef is on by default because the newish "Simplified API" needs it. (It appears it was off by default in 1.4, but now is on again). Some implementations on libpng turn it off.

Why hassle with this very C specific type of error handling? It's a very fast performing way to to handle unlikely errors. In addition, `setjmp` saves the calling environment to be used by `longjmp`. This means inside the set jump block using `png_ptr`, `info_ptr`, or even returning will all work. C callbacks, by contrast, can only use what get offered to them as parameters. 

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

That said, to side step all of this one could use functions from the aforementioned "Simplified libpng API" (No examples of that in this repo as it only works for indexed colors), which return UInt32 error codes. 


#### Why not just use custom error functions?

Well, this code tries with `buildSimpleDataExample` and `writeErrorCallback` but it doesn't end up with anything that useful.

Setting the error functions in the `png_create_*_struct` functions, i.e.  `(png_voidp)user_error_ptr, user_error_fn, user_warning_fn)` is not common in example code, but can be done. However, these functions STILL need to have `jmpdef`'s in them to permanently leave `libpng`'s functions so they are not a way to avoid `jmpdef`.  

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
        - [PngFile.c](https://github.com/glennrp/libpng/blob/a37d4836519517bdce6cb9d956092321eca3e73b/contrib/visupng/PngFile.c)
        - [timepng.c](https://github.com/glennrp/libpng/blob/5f5f98a1a919e89f0bcea26d73d96dec760f222f/contrib/libtests/timepng.c)
        - [pngvalid.c](https://github.com/glennrp/libpng/blob/61bfdb0cb02a6f3a62c929dbc9e832894c0a8df2/contrib/libtests/pngvalid.c)
        - [writepng.c](https://github.com/glennrp/libpng/blob/a37d4836519517bdce6cb9d956092321eca3e73b/contrib/gregbook/writepng.c)

The addition of an ErrorPointer struct that could hold needed information to pass the the error function can help with clean up. The error_ptr is a `void*`, as long as YOU know what it is, it can be whatever you need.
    
If the user will just leave the program at this point missing a dealloc may not the biggest deal, but file IO and network might not be closed, so be sure to check. 
    
If your callback nopes out with an `exit` or `abort`, this "Quitting behavior" will prevent being accepted into the app store. That's also no better than libpng default, so almost might as well have left it nil.

the `buildSimpleDataExample` calls a working, but not super useful, callback example.

#### What to do instead?

The solution, more C Code. I've separated it from the `libpng` wrapper for clarity.

The basic model of what I've done is to write a C function that wraps the calls to `libpng` and sets the long jump definitions accordingly. This allows for a developers-choice int to be returned if something goes wrong.

```C
int pngb_set_IHDR(png_structp png_ptr, png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth, int color_type, int interlace_method, int compression_method, int filter_method) {
    
    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_write_struct(&png_ptr, &info_ptr);
        return 2;
    }
    
    png_set_IHDR(png_ptr, info_ptr, width, height, bit_depth, color_type, interlace_method, compression_method, filter_method);
    
    return 0;
}
```

A companion Swift function that throws the appropriate error:

```Swift 
    static func setIHDR(png_ptr:OpaquePointer, info_ptr:OpaquePointer, width:UInt32, height:UInt32,
                        bitDepth:Int32, colorType:Int32) throws {
        let result = pngb_set_IHDR(png_ptr, info_ptr, width, height, bitDepth, colorType,                     
                                   PNG_INTERLACE_NONE,
                                   PNG_COMPRESSION_TYPE_DEFAULT,
                                   PNG_FILTER_TYPE_DEFAULT)
        if result != 0 {
            //PNGError implemented with an init that takes a code.
            throw PNGError(result) 
        }
    }
```

It means: 
- Lots of boiler plate for almost every `libpng` function call (although just the ones that can fail)
- A performance slow down for all the extra code checking.
- A whole separate target written in C.

For an example of how this pattern works see `SwiftLIBPNG+ThrowingData.swift` and some of the callbacks defined in `SwiftLIBPNG.swift`

### Why doesn't the IDAT look like the pixels that were passed in/out of libpng?

The full explanation? <http://www.libpng.org/pub/png/book/chapter09.html>

PNG's claim to fame is it's LOSSLESS compression, but it is, by default, compressed. Compressed RGBA data will look nothing like the colors you put in unless you specifically ask your PNG writer to not compress. These are your options (from the link above)
|Style  |Description|
|-------|-----------|
|None|Each byte is unchanged.|
|Sub|Each byte is replaced with the difference between it and the ``corresponding byte'' to its left.|
|Up|Each byte is replaced with the difference between it and the byte above it (in the previous row, as it was before filtering).|
|Average|Each byte is replaced with the difference between it and the average of the corresponding bytes to its left and above it, truncating any fractional part.|
|Paeth|Each byte is replaced with the difference between it and the Paeth predictor of the corresponding bytes to its left, above it, and to its upper left.|
 
 
  To choose your filter types, during the write process one can `png_set_filter`. Explanation from the manual section `IV. Writing`:
 
 >If you have no special needs in this area, let the library do what it wants by
not calling this function at all, as it has been tuned to deliver a good
speed/compression ratio. The second parameter to png_set_filter() is
the filter method, for which the only valid values are 0 (as of the
July 1999 PNG specification, version 1.2) or 64 (if you are writing
a PNG datastream that is to be embedded in a MNG datastream).  The third
parameter is a flag that indicates which filter type(s) are to be tested
for each scanline.  See the PNG specification for details on the specific
filter types.
 
 ```
     png_set_filter(png_ptr, 0,
       PNG_FILTER_NONE  | PNG_FILTER_VALUE_NONE |
       PNG_FILTER_SUB   | PNG_FILTER_VALUE_SUB  |
       PNG_FILTER_UP    | PNG_FILTER_VALUE_UP   |
       PNG_FILTER_AVG   | PNG_FILTER_VALUE_AVG  |
       PNG_FILTER_PAETH | PNG_FILTER_VALUE_PAETH|
       PNG_ALL_FILTERS  | PNG_FAST_FILTERS);
```
What the actual mask values are from `png.h` 
    
```C
/* Flags for png_set_filter() to say which filters to use.  The flags
 * are chosen so that they don't conflict with real filter types
 * below, in case they are supplied instead of the #defined constants.
 * These values should NOT be changed.
 */
#define PNG_NO_FILTERS     0x00
#define PNG_FILTER_NONE    0x08
#define PNG_FILTER_SUB     0x10
#define PNG_FILTER_UP      0x20
#define PNG_FILTER_AVG     0x40
#define PNG_FILTER_PAETH   0x80
#define PNG_FAST_FILTERS (PNG_FILTER_NONE | PNG_FILTER_SUB | PNG_FILTER_UP)
#define PNG_ALL_FILTERS (PNG_FAST_FILTERS | PNG_FILTER_AVG | PNG_FILTER_PAETH)

/* Filter values (not flags) - used in pngwrite.c, pngwutil.c for now.
 * These defines should NOT be changed.
 */
#define PNG_FILTER_VALUE_NONE  0
#define PNG_FILTER_VALUE_SUB   1
#define PNG_FILTER_VALUE_UP    2
#define PNG_FILTER_VALUE_AVG   3
#define PNG_FILTER_VALUE_PAETH 4
#define PNG_FILTER_VALUE_LAST  5

```
 
 One can also do things like:
 
 - Change the compression buffer size: set the `png_set_compression_buffer_size(png_ptr, buffer_size);`
 - Ask for a bigger space for your IDAT data `png_set_chunk_malloc_max(png_ptr, user_chunk_malloc_max);`
 
 To talk to zlib directly (don't): 
 
 - `png_set_compression_level` e.g. `png_set_compression_level(png_ptr, Z_BEST_COMPRESSION);`
 
 Most users of `libpng` will not need to fiddle with these settings, but its helpful to know why the data doesn't match what its given by default. 

### Why does the PNG writing example use Data instead of [UInt8]?

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

There is apparently a simpler API. However, they target "in-memory bitmap formats" not RGBA, which this project requires. 

>A "simplified API" has been added (see documentation in png.h and a simple
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
