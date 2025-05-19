# coal

![](./docs/coal_logo.png)

Coal is a CLI tool that simplifies creating and building C++ projects using CMake.

<video width="700" height="300" controls>
  <source src="./docs/coal_01.mp4" type="video/mp4">
</video>

## Usage

Create a new project:

```sh
coal init --name "projectName"
```

Build the project:

```sh
coal build
```

Run the project:

```sh
coal run
```

When you add new source files, they are automatically included in the next build:

```sh
vim src/something.cpp
...

coal build
```


## Installing

Download pre-built binaries in the [releases](https://github.com/magley/coal/releases) page.

Alternatively, you can build coal yourself. Coal is written in D and uses `dub` as a build tool:

```sh
git clone https://github.com/magley/coal.git
cd coal
dub build
```

> [!WARNING]
> Windows Defender may incorrectly flag the program as malware due to its unfamiliarity with the D Language runtime. 

To use coal, you must have CMake and C++ compiler installed.


## Templates

Instead of creating a new project from scratch, you can declare a template to use as a base.
<br/>
A template is a soft link to a folder with code. All templates are defined in `templates.json`. Templates do not have to be coal projects.

- Initialize a new template:

```sh
coal template new 
    --name "OpenGL template" 
    --desc "Create a window and draw a triangle" 
    --path "D:/foo/bar/my_opengl_project"
```

- Create a new project using the existing template:

```sh
coal template clone 
    --template "OpenGL template" 
    --name "My new program"
```

When you clone a template, all of its files are copied to the new project, except for:
- `.git/`
- `CMakeLists.txt`
- The build folder (except for `coalfile.private`)


## Dependency management

Coal isn't a package manager, but you can add local libraries with ease.

For example, you can link a dynamic library like SDL3 in the following way:

```sh
coal add
    --name "SDL3"
    --path "<path-to-sdl3-on-your-computer>"
    --include "include/"
    --lib "lib/"
    --dll "bin/SDL3.dll"
    --link "SDL3"
```

Dear ImGUI is linked in a similar way. Since the library must be built with your project, you have to specify which `.cpp` files for CMake to build. For ImGUI, you only need a single backend along with the core files:

```sh
coal add
    --name "ImGUI"
    --path "<path-to-imgui-on-your-computer>"
    --include "." "imgui/"
    --source "imgui/imgui.cpp" \
             "imgui/imgui_draw.cpp" \
             "imgui/imgui_tables.cpp" \
             "imgui/imgui_widgets.cpp" \
             "imgui/backends/imgui_impl_sdl3.cpp"\
             "imgui/backends/imgui_impl_sdlrenderer3.cpp" \
             "imgui/misc/cpp/"
```

## The coalfile

All project data is stored in a `coalfile`, which is a descriptive JSON file that's used to generate a `CMakeLists.txt`.

The `coalfile` is automatically created on `coal init`, and is updated whenever a new library is added through `coal add`. Other properties, like the version of C++ or the compiler flags, are modified directly inside `coalfile`.

Example coalfile:

```json
{
    "name": "example",
    "source_dirs": [ "src/" ],
    "build_dir": "build/",
    "generator": "MinGW Makefiles",

    "flags": [],
    "build_specific_flags": {
        "debug": ["O0", "g", "DDEBUG"],
        "minsize": ["Os", "DNDEBUG"],
        "none": [],
        "release": ["O3", "DNDEBUG" ],
        "releasedebug": ["O2", "g", "DNDEBUG"]
    },
    "link_flags": [],

    "cpp_version": "14",
    "cmake_version_min": "3.15",
    "cmake_version_max": "4.0",
    "libs": [],
}
```

There is one more file required to build projects, `coalfile.private`, which stores the full path to each dependency added through `coal add`. <br/>
This data is private and non-portable, so it is kept in the build directory of your project and is **not** meant to be included in version control.

## Motivation

Languages like D, Go, Rust etc. all come with a build system that
follows an easy pattern:

1. `${TOOL} init`
2. Create source files
3. Write code to the source files.
4. `${TOOL} build/run`

C++ is different. The agreed-upon way of building projects in C++ is through CMake, which requires a lot of maintenance and bookkeeping. In addition to the 4 steps above, you must also to specify every `.cpp` file in `CMakeLists.txt`. If you do fast iterations, having to wait for the project to build 40% the way through only to learn that you forgot to add the new `.cpp` files is frustrating. If you rename the file, you have to update `CMakeLists.txt`. Glob patterns exist, but they are slow and you still have to _both_ configure and build every time there's a change.

coal frees the programmer from babysitting CMake. It generates a simple `CMakeLists.txt` and provides you with a barebones CLI to build and run projects.

## What coal isn't

coal isn't a package manager. You must download the libraries yourself. 

coal isn't a CMake alternative. It works _on top_ of CMake.

coal cannot be retrofitted to existing CMake projects.

## Design principles

### Opt-out at any time.

Don't want to use coal anymore? Just delete `coalfile` and use CMake directly!

### You are in full control

There is no hidden caching or duplication of files. Everything is stored in `coalfile` and `coalfile.private`.

## License

Coal uses the BSD-2-Clause license. See `LICENSE` for more info.