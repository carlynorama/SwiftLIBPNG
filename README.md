# SwiftLIBPNG

A lightweight wrapper around libpng done to learn the process. 


## Making A Wrapper

### References
- [How to use C libraries in Swift?](https://theswiftdev.com/how-to-use-c-libraries-in-swift/)
-  [How to wrap a C library in Swift](https://www.hackingwithswift.com/articles/87/how-to-wrap-a-c-library-in-swift), but also its more [up to date repo](https://github.com/twostraws/SwiftGD)
- [Making a C library available in Swift using the Swift Package Manager](https://rderik.com/blog/making-a-c-library-available-in-swift-using-the-swift-package/)


### Learn about the library you want to wrap.

```zsh
brew install $THING_TO_WRAP
cd /usr/local/include/
ls -a 
# look for header file of $THING_TO_WRAP so you know its name for later. 
```

### Start the Library 

```zsh
mkdir $YOUR_LIBRARY_NAME
cd $YOUR_LIBRARY_NAME
# Note HWS tutorial uses `system-module` which appears to be deprecated. 
swift package init --type library 
```

#### Update Package.swft target's section to include a reference to the installed C system library


The `pkgConfig` name is optional. It can be found by (on a computer with pkg-config installed) with `pkg-config --list-all | grep $THING_TO_WRAP` or some fraction of the `$THING_TO_WRAP` name. My understanding is that the "name" is the same as the header file's name w/o the .h

```swift
.systemLibrary(name: "png", pkgConfig: "libpng", providers: [.apt(["libpng-dev"]), .brew(["libpng"])]),
```

#### Create a module.modulemap file

If using the deprecated(?) system-module command this was created for you at the top level, but when using the library. This file is what really tells the compiler where to find the libary. We have choices here, to make a regular header, a shim header, a briding header, and umbrella header... I've gone with an umbrella header like the SwiftGD repo. 

```zsh
cd Sources
mkdir libpng #replace with system c module name
cd libpng
touch module.modulemap
touch swiftlibpng_libpng.h
```

module.modulemap contains

```
module png {
	umbrella header "swiftlibpng_libpng.h"
	link "png"
}
```

and the refernced file (swiftlibpng_libpng.h) contains the one line `#include <png.h>` 



