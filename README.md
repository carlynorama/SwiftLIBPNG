# SwiftLIBPNG

A lightweight wrapper around libpng done to learn the process. 

- <http://www.libpng.org>
- <http://www.libpng.org/pub/png/book/>


## Making A Wrapper

### References
- [How to use C libraries in Swift?](https://theswiftdev.com/how-to-use-c-libraries-in-swift/)
-  [How to wrap a C library in Swift](https://www.hackingwithswift.com/articles/87/how-to-wrap-a-c-library-in-swift), but also its more [up to date repo](https://github.com/twostraws/SwiftGD)
- [Making a C library available in Swift using the Swift Package Manager](https://rderik.com/blog/making-a-c-library-available-in-swift-using-the-swift-package/)
- <https://clang.llvm.org/docs/Modules.html>


### Learn about the library you want to wrap.

```zsh
brew install $THING_TO_WRAP
# Intel Mac
cd /usr/local/include/
# M1
cd /opt/homebrew/include
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

#### Update Package.swift target's section to include a reference to the installed C system library

In this example the `name` is the same as the folder where modulemap lives, which the same as the libraries header file (without the .h)), which is the same as the module map link. This kept it easiest for me. 

The `pkgConfig` name is purportedly optional? It can be found by (on a computer with pkg-config installed) with `pkg-config --list-all | grep $THING_TO_WRAP` or some fraction of the `$THING_TO_WRAP` name. I was not able to get a library to compile without `pkg-config` installed and without this parameter set. 

`providers` is definitely optional.

Neither `pkgConfig` or `providers` will auto install dependencies at this time (2023 Apr). 

```swift
.systemLibrary(name: "png", pkgConfig: "libpng", providers: [.apt(["libpng-dev"]), .brew(["libpng"])]),
```

Make sure to add the name to the library target's dependencies as well. 

#### Create a module.modulemap file

If using the deprecated(?) system-module command this was created for you at the top level, but when using the library. This file is what really tells the compiler where to find the library. We have choices here, to make a regular header, a shim header, a bridging header, or a umbrella header... I've gone with an umbrella header like the SwiftGD repo. 

```zsh
cd Sources
mkdir $SYSLIB_NAME # as referenced in the "name" parameter
cd $SYSLIB_NAME
touch module.modulemap
touch umbrella.h
```

`module.modulemap` contains

```
module png {
	umbrella header "umbrella.h"
	link "png"
}
```

`umbrella.h` contains the one line `#include <png.h>`


### If XCode is having Trouble finding the library

#### What does compiling in the command line say?

```
cd $PROJECT_DIR
swift package clean
swift build --verbose
```

#### Is `package-config` installed? 

`brew install pkg-config`

### Homebrew path correct?

When installing homebrew did you update the path? Especially important on M1 macs where the install path has changed to `/opt/homebrew/` from `/usr/local/include/`. 

Check `cat ~/.zprofile` it should exist and contain `eval "$(/opt/homebrew/bin/brew shellenv)"`

If `~/.zprofile` does not exist and contain that line run:
    ```
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval $(/opt/homebrew/bin/brew shellenv)
    ```

Commands run:
    ```
    export HOMEBREW_PREFIX="/opt/homebrew";
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
    export HOMEBREW_REPOSITORY="/opt/homebrew";
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
    export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
    ```

If this command provides no output if it has already been run. 

To check the path: `echo $PATH` it should now contain `/opt/homebrew/bin:/opt/homebrew/sbin:`

