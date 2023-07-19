
# Making A External C Library Wrapper

## References
- [How Swift imports C APIs](https://github.com/apple/swift/blob/main/docs/HowSwiftImportsCAPIs.md)
- [How to use C libraries in Swift?](https://theswiftdev.com/how-to-use-c-libraries-in-swift/)
-  [How to wrap a C library in Swift](https://www.hackingwithswift.com/articles/87/how-to-wrap-a-c-library-in-swift), but also its more [up to date repo](https://github.com/twostraws/SwiftGD)
- [Making a C library available in Swift using the Swift Package Manager](https://rderik.com/blog/making-a-c-library-available-in-swift-using-the-swift-package/)
- <https://clang.llvm.org/docs/Modules.html>
- [Guide to including a C library into an iOS project written in Swift](https://rlaguilar.com/posts/integrate-c-library-ios-project-swift/)
- [PackageManager BuildSettings Proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0238-package-manager-build-settings.md) (implemented)
- [PackageManager LinkerSettings](https://developer.apple.com/documentation/packagedescription/linkersetting) for when it really is a System library? 
- (2016) http://nsomar.io/modular-framework-creating-and-using-them/
- https://medium.com/@yuliiasynytsia/link-static-c-library-to-swift-framework-as-a-private-module-97eae2fec75e
- https://developer.apple.com/forums/thread/42737



## Getting Started

### Learn about the library you want to wrap.

```zsh
brew install $THING_TO_WRAP 
# Intel Mac
cd /usr/local/include/
# Apple Silicon
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

<https://developer.apple.com/documentation/packagedescription/target/systemlibrary(name:path:pkgconfig:providers:)>

In this example the `name` is the same as the folder where modulemap lives, which the same as the libraries header file (without the .h)), which is the same as the module map link. This kept it easiest for me. 

The `pkgConfig` parameter is an [optional](https://developer.apple.com/documentation/packagedescription/target/systemlibrary(name:path:pkgconfig:providers:)) setting, but it does appear to be required for libraries not really in the the System or in the CommandLineTools SDK. The name needed can be found by (on a computer with pkg-config installed) with `pkg-config --list-all | grep $THING_TO_WRAP` or some fraction of the `$THING_TO_WRAP` name. I was not able to get this package to compile without `pkg-config` installed and without this parameter set. My guess is that is because `libpng` is not a real System Library, nor in the CommandLineTools SDK.

`providers` is truly optional adding `providers` will NOT auto install dependencies at this time (2023 Apr). 

```swift
.systemLibrary(name: "png", pkgConfig: "libpng", providers: [.apt(["libpng-dev"]), .brew(["libpng"])]),
```

Make sure to add the name to the library target's dependencies as well. 

#### Create a module.modulemap file

If using the deprecated(?) system-module command this was created for you at the top level, but when using the --library initializer it has to be done by hand. This file is what really tells the compiler where to find the library. We have choices here, to make a regular header, a shim header, a bridging header, or a umbrella header... I've gone with an umbrella header like the SwiftGD repo. 

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


## If XCode is having Trouble finding the library

#### What does compiling in the command line say?

```
cd $PROJECT_DIR
swift package clean
swift build --verbose
```

#### Is `package-config` installed? 

`brew install pkg-config`

#### Homebrew path correct?

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

## Build Issues by Platform

Have I gotten this library to compile for... 

### Intel Mac

Yes, totally fine with `pkg-config` installed.

### Apple Silicon Mac

Yes, totally fine with `pkg-config` installed.

### iOS Simulator: No

Not a high priority to fix. 

```
Building for iOS Simulator, but linking in dylib built for macOS, file '/usr/local/opt/libpng/lib/libpng16.dylib' for architecture x86_64
```

Options:

- https://developer.apple.com/forums/thread/657913
- https://stackoverflow.com/questions/63607158/xcode-building-for-ios-simulator-but-linking-in-an-object-file-built-for-ios-f
- https://www.dynamsoft.com/barcode-reader/docs/mobile//programming/objectivec-swift/faq/arm64-simulator-error.html
- https://rlaguilar.com/posts/integrate-c-library-ios-project-swift/
- https://thisisyuu.github.io/2020/MISC-Building-universal-binaries-from-C-library-for-an-iOS-project/

### iOS Hardware: No

Not a high priority to fix. 

```Linker command failed with exit code 1 (use -v to see invocation)```

Related to above.


### Linux (Ubuntu) install: Yes

From fresh. 

[Add Swift](https://www.swift.org/server/guides/deploying/ubuntu.html)
```zsh
sudo apt update
sudo apt upgrade
sudo apt install clang libicu-dev build-essential pkg-config

mkdir ~/swift
cd ~/swift
# go to https://www.swift.org/download/#releases for current links
wget https://download.swift.org/swift-5.8-release/ubuntu2004/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu20.04.tar.gz
tar xzf swift-5.8-RELEASE-ubuntu20.04.tar.gz #add v (xzvf) to see all files
mv swift-5.8-RELEASE-ubuntu22.04 5.8
# swift.org recommended choice: add a simlink to `swift` command to `/usr/bin/` 
# instead of adding version folder to $PATH. 
sudo ln -s ~/swift/5.8/usr/bin/swift /usr/bin/swift 
swift --version
```

Add what we need:

```zsh
sudo apt install git 
sudo apt install gh  #optional
sudo apt install libpng-dev

mkdir ~/Documents/GitHub
cd ~/Documents/GitHub

gh auth login #https://cli.github.com/manual/gh_auth_login
gh repo clone carlynorama/SwiftLIBPNG

#or
git@github.com:carlynorama/SwiftLIBPNG.git

cd SwiftLIBPNG
swift build
```

If installing VScode will also need sourcekit-lsp. Discussion: <https://forums.swift.org/t/vscode-extension/29722>


### Fake Linux (Github Action)

Use action like one checking [APITizer](https://github.com/carlynorama/APItizer/actions)

```yml
name: Build Linux

on:
  push:
    branches:
      - '*'
  pull_request:
    branches:
      - main
      
jobs:
  build:
    name: Build Linux
    runs-on: ubuntu-latest
    container:
      image: swift:latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Install sudo package
        run: apt update && apt install sudo
      - name: Install libpng
        run: |
          sudo apt-get install libpng-dev -y
      - name: Build and Test
        run: |
           swift build
           swift test
```

