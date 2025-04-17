'''
Copyright 2025 magley

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'''



import argparse
import os
import json
import subprocess

os.system('color')

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


# ------------------------------------------

def subprocess_fancy(args: list, error_msg):
    try:
        result = subprocess.run(args, 
                       check=True, 
                       stdout=subprocess.PIPE, 
                       stderr=subprocess.PIPE, 
                       text=True,
                       encoding="utf-8")
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)

    except subprocess.CalledProcessError as e:
        print(f"{bcolors.FAIL}[!] {error_msg} (error code {e.returncode}{bcolors.ENDC})")
        print(f"{bcolors.FAIL}{e.stdout}{bcolors.ENDC}")
        print(f"{bcolors.FAIL}{e.stderr}{bcolors.ENDC}")
        exit(e.returncode)
 

def input_basic(prompt: str) -> str:
    return input(f'{bcolors.HEADER}{prompt}{bcolors.ENDC}')

def input_multi(prompt: str, allow_none = False) -> list:
    ss = []
    s = ""

    while True:
        s = input_basic(prompt)
        s = s.strip()

        if s == "":
            if allow_none:
                break
            if len(ss) > 0:
                break
        else:
            ss.append(s)
    
    return ss 

def input_not_none(prompt: str) -> str:
    s = ""
    while s == "":
        s = input_basic(prompt)
        s = s.strip()
    return s

def input_path_dir(prompt: str):
    p = ""
    while p == "":
        p = input_basic(prompt)

        if not os.path.exists(p):
            print(f"{bcolors.WARNING}Path not found{bcolors.ENDC}")
            p = ""
        elif not os.path.isdir(p):
            print(f"{bcolors.WARNING}Path must be a directory{bcolors.ENDC}")
            p = ""

    return p.replace("\\", "/")

# ------------------------------------------

parser = argparse.ArgumentParser("coal parser")
parser.add_argument("command", choices=["init", "build", "run", "add"])

args = parser.parse_args()

COALFILE_PATH = "coalfile"
COALFILE_PRIVATE_PATH = None # Depends on output_dir in coalfile

CONTEXT = None
CONTEXT_PRIVATE = None

try:
    with open(COALFILE_PATH, 'r') as f:
        CONTEXT = json.loads(f.read())
except FileNotFoundError:
    pass

if CONTEXT is not None:
    if not 'output_dir' in CONTEXT:
        print(f"{bcolors.FAIL}Broken coalfile (missing 'output_dir' field){bcolors.ENDC}")
        exit(1)

    output_dir = CONTEXT['output_dir']

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

    COALFILE_PRIVATE_PATH = os.path.join(output_dir, 'coalfile.private').replace('\\', '/')
    try:
        with open(COALFILE_PRIVATE_PATH, 'r') as f:
            CONTEXT_PRIVATE = json.loads(f.read())
    except FileNotFoundError:
        pass

def get_lib_variable_name(lib_name: str):
    return f"{lib_name}_DIR"

def get_lib_variable(lib_name: str):
    return '${' + get_lib_variable_name(lib_name) + '}'

# ------------------------------------------

def build():
    SOURCE_FILE_EXT = ".cpp"
    VERSION = '1.0'
    LANGUAGE = 'CXX'
    CPP_STANDARD = "17"
    EXE_NAME = CONTEXT['name']
    OUTPUT_DIR = CONTEXT['output_dir']
    GENERATOR = CONTEXT['generator']

    # List of environment variables that are paths.
    # set(* $ENV{*} CACHE PATH)
    env_paths = []

    # List of directories with header files. Root dir is enough.
    include_directories = []

    # List of source files that will be compiled, relative to project.
    source_files = []

    # List of directories to link against.
    link_directories = []

    # Which libraries to link against.
    link_libraries = []

    # Copy DLL files after build.
    dll_files = []

    for dir in CONTEXT['source_folders']:
        include_directories.append(dir)

        for root, _, files in os.walk(dir):
            for file in files:
                if file.endswith(SOURCE_FILE_EXT):
                    path_rel = os.path.join(root, file).replace("\\","/")
                    source_files.append(path_rel)

    
    for lib in CONTEXT['libraries']:
        lib: dict = lib
        lib_env_dir = get_lib_variable(lib['name']) # value is: ${name_DIR}

        # Create a set(....) path env variable for this library.
        env_paths.append(lib['name'])

        # Add the library's include variable to include_directories
        if 'include_dir' in lib:
            lib_include_dir = lib['include_dir']

            lib_include_dir_value = os.path.join(lib_env_dir, lib_include_dir).replace("\\","/")
            include_directories.append(lib_include_dir_value)
    
        # Add the library's link directory to link_directories
        if 'link_dir' in lib:
            lib_link_dir = lib['link_dir']

            lib_link_dir_value = os.path.join(lib_env_dir, lib_link_dir).replace("\\","/")
            link_directories.append(lib_link_dir_value)

        # Add the library's name to target_link_libraries
        if 'link_libraries' in lib:
            for l in lib['link_libraries']:
                link_libraries.append(l)

        # Add DLL files for this library (if any).
        if 'dll_files' in lib:
            for dll in lib['dll_files']:
                lib_link_dir_value = f'{lib_env_dir}/{dll}'.replace("\\", "/").replace("//", "/")
                dll_files.append(lib_link_dir_value)


    #### Make CMakeLists.txt

    lines = []

    lines.append('cmake_minimum_required(VERSION 3.15...4.0)')
    lines.append('')
    lines.append(f"project({CONTEXT['name']} VERSION {VERSION} LANGUAGES {LANGUAGE})")
    lines.append(f"set(CMAKE_CXX_STANDARD {CPP_STANDARD})")
    lines.append(f"set(CMAKE_EXPORT_COMPILE_COMMANDS 1)")

    lines.append('')

    for lib_name in env_paths:
        name = get_lib_variable_name(lib_name)
        var = get_lib_variable(lib_name)
        lines.append(f'set({name} {var} CACHE PATH "Path to {lib_name}")')
    lines.append('')

    lines.append('include_directories(')
    for d in include_directories:
        lines.append("    " + d)
    lines.append(')')
    lines.append('')

    lines.append('link_directories(')
    for d in link_directories:
        lines.append("    " + d)
    lines.append(')')
    lines.append('')

    lines.append('set(SOURCES')
    for d in source_files:
        lines.append("    " + d)
    lines.append(')')
    lines.append('')

    lines.append('add_executable(' + EXE_NAME + f" {source_files[0]}" + " ${SOURCES})")
    lines.append('')

    lines.append(f'target_link_libraries({EXE_NAME}')
    for l in link_libraries:
        lines.append("    " + l)
    lines.append(')') 
    lines.append('')


    if len(dll_files) > 0:
        lines.append('if(WIN32)')
        lines.append(f'\tadd_custom_command(TARGET {EXE_NAME} POST_BUILD')
        for dll in dll_files:
            _cmake_command = "${CMAKE_COMMAND}"
            l = f'COMMAND {_cmake_command} -E copy_if_different "{dll}" $<TARGET_FILE_DIR:{EXE_NAME}>'

            lines.append(f'\t\t{l}')

        lines.append('\t)')
        lines.append('endif()')


    cmakelists = '\n'.join(lines)

    with open('CMakeLists.txt', 'w') as f:
        f.write(cmakelists)

    #### Build

    output_dir_path = os.path.join('./', OUTPUT_DIR).replace("\\","/")
    if not os.path.exists(output_dir_path):
        os.mkdir(output_dir_path)

    env = os.environ.copy()
    env_vars_cmdarg = []
    for k, v in CONTEXT_PRIVATE['environment'].items():
        env[get_lib_variable_name(k)] = v
        env_vars_cmdarg.append(f'-D{get_lib_variable_name(k)}={v}')

    print(f"{bcolors.OKGREEN}* Configuring {EXE_NAME}...{bcolors.ENDC}")
    subprocess_fancy(["cmake", "-S", ".", "-B", OUTPUT_DIR, "-G", GENERATOR, *env_vars_cmdarg],
                     f"Coal failed to configure {EXE_NAME}")

    print(f"{bcolors.OKGREEN}* Building {EXE_NAME}...{bcolors.ENDC}")
    subprocess_fancy(["cmake", "--build", "build"], f"Coal failed to build {EXE_NAME}")

def run():
    OUTPUT_DIR = CONTEXT['output_dir']
    EXE_NAME = CONTEXT['name']

    run_from_root = os.path.join(OUTPUT_DIR, EXE_NAME)
    exe_path  = os.path.abspath(run_from_root + '.exe')

    print(f"{bcolors.OKGREEN}'* Executing' {exe_path}{bcolors.ENDC}")
    subprocess.run(exe_path)

def input_library() -> dict:
    lib = {}
    lib['name'] = input_not_none('1/6 Name (*): ')
    lib['path'] = input_path_dir("2/6 Root directory path (*): ")
    lib['include_dir'] = input_basic("3/6 Include directory (relative to path): ")
    lib['link_dir'] = input_basic("4/6 Lib directory (relative to path): ")
    lib['link_libraries'] = input_multi("5/6 Lib to link (one per line, empty input to finish): ", True)
    lib['dll_files'] = input_multi("6/6 DLL file to link (relative to path) (one per line, empty input to finish): ", True)
    return lib

def input_libraries(prompt: str) -> list:
    '''
    input expects y/n
    prompt should print that out
    '''

    libraries = []

    s = "y"
    while s == "y":
        s = input_basic(prompt)
        s = s.strip()
        if s == "": s = "n"
        elif s in ['Y', 'y']: s = "y"
        elif s in ['N', 'n']: s = "n"
        else:
            continue

        if s == 'y':
            try:
                lib = input_library()
                libraries.append(lib)
            except KeyboardInterrupt:
                print()
                continue

    return libraries

def init():
    coalfile = {}

    # ---- Proceed with the input wizard
    # Input everything required to start a coalfile project.
    # This may not be the final format of the coalfile data.

    coalfile["name"] = input_not_none("1/4 Project name (*): ")
    coalfile["source_folders"] = input_multi("2/4 Source directories (one per line, empty input to finish) (*): ")
    coalfile["output_dir"] = input_not_none("3/4 Output dir (*): ")
    coalfile["generator"] = "MinGW Makefiles"
    coalfile["libraries"] = [] # input_libraries("4/4 Add library (y/n) [n]: ")


    # ---- Create coalfile.private
    # Every library has a path which sould not be inside the coalfile
    # So we have to extract lib['path'] and map the library's name to that path
    # The mapping is for env variable substitution in cmake files.

    coalfile_private = {}
    coalfile_private["environment"] = {}

    for lib in coalfile['libraries']:
        coalfile_private['environment'][lib['name']] = lib['path']
        del lib['path']

    # ---- Save files

    with open(COALFILE_PATH, "w") as f:
        f.write(json.dumps(coalfile, indent=4))
    with open(COALFILE_PRIVATE_PATH, "w") as f:
        f.write(json.dumps(coalfile_private, indent=4))

def add_lib():
    global CONTEXT, CONTEXT_PRIVATE
    library = input_library()

    CONTEXT_PRIVATE['environment'][library['name']] = library['path']
    del library['path']
    CONTEXT['libraries'].append(library)

    with open(COALFILE_PATH, "w") as f:
        f.write(json.dumps(CONTEXT, indent=4))
    with open(COALFILE_PRIVATE_PATH, "w") as f:
        f.write(json.dumps(CONTEXT_PRIVATE, indent=4))

def handle_missing_coalfile():
    global CONTEXT, CONTEXT_PRIVATE

    if CONTEXT is None and CONTEXT_PRIVATE is None:
        print(f"{bcolors.FAIL}Please generate a coalfile with `init`{bcolors.ENDC}")
        exit(1)

    if CONTEXT is not None and CONTEXT_PRIVATE is None:
        print(f"{bcolors.FAIL}coalfile.private missing or deleted{bcolors.ENDC}\nGenerating a new one...\n")
        CONTEXT_PRIVATE = {
            "environment": {}
        }
    
    # If env is missing library paths, add them now.

    libs = [l['name'] for l in CONTEXT['libraries']]
    lib_envs_missing = [l for l in libs if l not in CONTEXT_PRIVATE['environment']]

    if len(lib_envs_missing) > 0:
        print(f"{bcolors.FAIL}Library environments missing:{bcolors.ENDC} {','.join(lib_envs_missing)}")

        for lib in lib_envs_missing:
            p = input_path_dir(f"Enter root path for library {bcolors.UNDERLINE}{lib}{bcolors.ENDC}: ")
            CONTEXT_PRIVATE["environment"][lib] = p

    # Save coalfile and coalfile.private with the new changes.

    with open(COALFILE_PATH, "w") as f:
        f.write(json.dumps(CONTEXT, indent=4))
    with open(COALFILE_PRIVATE_PATH, "w") as f:
        f.write(json.dumps(CONTEXT_PRIVATE, indent=4))

# ------------------------------------------

if args.command == 'init':
    init()
elif args.command == 'build':
    handle_missing_coalfile()
    
    build()
elif args.command == 'run':
    handle_missing_coalfile()

    build()
    run()
elif args.command == 'add':
    handle_missing_coalfile()

    add_lib()