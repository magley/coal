# coal - Automate the boring parts of CMake

![](./docs/coal_logo.png)

`coal` is a CLI tool I've made to speed up bootstrapping C++ projects.

Languages like D, Go, Rust etc. all come with a build system that
follows an easy pattern:

1. `${TOOL} init`
2. Create source files
3. Write code to the source files.
4. `${TOOL} build/run`

C++ is different. The agreed-upon way of building projects in C++ is through CMake. CMake requires a lot of maintenance and bookkeeping. In addition to the 4 steps above, you must also to specify every `.cpp` file in `CMakeLists.txt`. I do fast iterations, so having to wait for the project to build 40% the way through only to learn that I forgot to add my new `.cpp` files is frustrating. If you rename the file, you have to update `CMakeLists.txt`. Glob patterns exist, but they are slow and you still have to _both_ configure and build every time there's a change.

`coal` frees the programmer from babysitting CMake. It generates a simple `CMakeLists.txt` and provides you with a barebones CLI to build and run projects.

## What `coal` isn't

`coal` isn't a package manager. You must download any libraries yourself. 

`coal` isn't a CMake alternative. It works in junction with CMake and you may opt out at any time.

`coal` isnt'a plug-n-play tool for existing CMake projects. This may change in the future.

## Usage

`coal` assumes CMake and a C++ compiler are installed. At the moment, `coal` is hardcoded to use the MinGW compiler.

```sh
# Initialize a new project
coal init

# Build the project
coal build

# Build and run the project
coal run

# Add a local library to the project
coal add
```

## Features

### Adding local libraries

If your project depends on a library, you may include it in your project using `coal add`. It's assumed that the library is downloaded locally to some location on your computer.

None of the files (except any Windows DLLs you specify) are copied to the project folder. Furthermore, the paths to the libraries aren't hardcoded either. Inside your build folder exists a `coalfile.private` which is where the paths are specified. This file should _not_ be staged for version control.

### Opt-out at any time.

Don't want to use `coal` anymore? Just delete `coalfile` and use CMake directly!

### You are in full control

There is no hidden caching or duplication of files. Everything is stored in `coalfile` and `coalfile.private`.

## License

Coal uses the BSD-2-Clause license. See `LICENSE` for more info.