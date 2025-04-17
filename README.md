# coal - Automate the boring parts of CMake

`coal` is a CLI tool that generates CMake files and builds projects.

## Manifesto

Working on C++ projects is frustrating, especially on Windows where you're
forced to download libraries manually and link them in one of 4+ ways. Compared
to build tools and package managers like `pip`, `dub`, `cargo` and others, it's
quite a hassle having to keep track of `.cpp` files and constantly update
`CMakeLists.txt`. It gets to the point that I feel reluctant to reogranize code
and even start new C++ projects.

My vision of `coal` is to be used as a bootstrap later C++ projects. It does _most_ of the work for you, while not getting in your way if you wish to stop using it.

## Usage

### Requirements:

- CMake, download [here](https://cmake.org/)
- Python, download [here](https://python.org/)
- A C++ compiler, at the moment `coal` is hard-coded to use MinGW which you can download [here](https://www.mingw-w64.org/downloads/)

### Pattern:

The idea behind `coal` is that you drag-and-drop (or softlink) the `coal.py` script to a directory and use it to generate a project. `coal.py` should be located at the root of the project. 

### Commands:

```sh
# Initialize a project. This will start a CLI wizard.
python coal.py init

# Build the project. This command will prepare CMake (if needed). 
python coal.py build

# Build and run the project.
python coal.py run

# Add a (local) library to the project. This will start a CLI wizard.
python coal.py addlib
```

## Features

### Embrace CMake, don't replace it

`coal` is not a replacement for CMake. It automates the creation of
`CMakeLists.txt` and invokes the configuration and build commands (using the
MinGW generator).

### Opt-out any time.

If you change your mind and want to use CMake directly, just delete `coal.py` and `coalfile`. 

### You are in full control

The CLI is inspired by tools such as `pip`, `dub`, `npm`, `cargo` etc., but
`coal` is **not** a package manager. You have to obtain the libraries
externally, but you also know where they are.

There is no hidden caching or duplication of files. 

### Sane

All the information for a project is stored in the `coalfile` which is generated when you run `coal init`. It's human-readable JSON that defines a C++ project and you are welcome to modify it manually (except when adding libraries which should be done through `coal addlib`).

One extra file is maintained in the build directory of your project: `coalfile.private`. It stores environment variables used by CMake. Currently it is used only to specify the full path of the libraries used by the project. <br/>
It is safe to delete `coalfile.private`, but you will be asked to input the required paths on your next build.

## Drawbacks

`coal` is very primitive. It was designed ad-hoc as a tool for a very specific use case.

`coal` cannot be used retroactively. Existing projects have a non-standard CMakeLists.txt which `coal` will override and most certainly break your project.

`coal` is meant to be used by a human. `coal` currently cannot be automated easily and is not meant to be part of a CI/CD workflow.

`coal`'s "do it mostly not yourself" philosophy is not for everyone. You are welcome to use one of the dozens of dead-on-arrival C++ package managers that break every update if you wish. 

## License

Coal uses the BSD-2-Clause license. See `LICENSE` for more info.