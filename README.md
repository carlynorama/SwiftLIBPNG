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
- Had information that I did not find in manual. Actually has code post v1.6 -><https://github.com/glennrp/libpng/blob/12222e6fbdc90523be77633ed430144cfee22772/INSTALL> 

- 'just the spec ma'am' - <https://www.w3.org/TR/2003/REC-PNG-20031110/>, <https://w3c.github.io/PNG-spec/>
- zlib spec for analyzing IDAT <https://www.zlib.net/manual.html>

### Inspecting Data

To just look at the HEX

- <https://hexed.it>
- VSCode plugin Microsoft Hex Editor 
- Shell option 1 `od -t x1 png-transparent.png`
- Shell option 2 for bigger files `tail -f png-transparent.png | hexdump -C`

Very handy PNG verifier: <https://www.nayuki.io/page/png-file-chunk-inspector>


## Notes

### Managing the pointers

To use `libpng` to read or write the first step is to allocate memory for structs libpng will use to store information about the png and its settings. 

From the documentation (on how to read, but a png_ptr and info_ptr are used for both reading a writing):

>The struct at which png_ptr points is used internally by libpng to keep track of the current state of the PNG image at any given moment; info_ptr is used to indicate what its state will be after all of the user-requested transformations are performed. One can also allocate a second information struct, usually referenced via an end_ptr variable; this can be used to hold all of the PNG chunk information that comes after the image data, in case it is important to keep pre- and post-IDAT information separate (as in an image editor, which should preserve as much of the existing PNG structure as possible). For this application, we don't care where the chunk information comes from, so we will forego the end_ptr information struct and direct everything to info_ptr.

The functions libpng provides for this come in two flavors, ones that return pointers and ones that take them and their handling functions in: 

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

Both styles of struct creation still require a call to `png_destroy_write_structs` functions on wrap up. 


- TODO: Case of the disappearing setjmp(png_jmpbuf(png_ptr))

- TODO: filter types
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
