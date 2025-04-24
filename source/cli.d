import std.stdio;
import std.string;
import std.algorithm.searching;
import core.stdc.stdlib;
import std.format;
import std.traits;
import std.conv;

/* -----------------------------------------------------------------------------
Entry point functions.

The program interfaces against `feed()`.

`on_feed()` creates the command object and performs the logic. Ideally this
function should not be doing any work directly, and should delegate the code to
other parts of the program. So "init" should create the Command_init struct and
then call do_init() which is defined in `init.d`.
----------------------------------------------------------------------------- */

void feed(string[] args)
{
    if (args.length < 2)
    {
        writeln("Use coal --help for a list of commands");
        return;
    }

    on_feed(args[1], args[2 .. $]);
}

private void on_feed(string command, string[] args)
{
    switch (command)
    {
    default:
        {
            writeln("Unknown command\nEnter coal help for a list of commands");
            break;
        }
    case "version":
        {
            import main;

            writefln("coal :: version %s", VERSION);
            break;
        }
    case "help":
        {
            writeln("coal :: CMake utility tool");
            writeln("Commands:");
            writeln("\tinit     - Initialize a new project");
            writeln("\tbuild    - Build project");
            writeln("\trun      - Run project");
            writeln("\tadd      - Add local library to project");
            writeln("\tFor more info on any of these commands, run `coal [command] --help`");
            writeln("\t");
            writeln("\thelp     - Open this help menu");
            writeln("\tversion  - Show version");

            break;
        }
    case "init":
        {
            import init;

            Command_init cmd = Command_init(args);
            do_init(cmd);
            break;
        }
    case "add":
        {
            import add;

            Command_add cmd = Command_add(args);
            do_add(cmd);
            break;
        }
    case "build":
        {
            import build;

            Command_build cmd = Command_build(args);
            do_build(cmd);
            break;
        }
    case "run":
        {
            import build;

            Command_run cmd = Command_run(args);

            if (!cmd.no_build.value)
            {
                Command_build cmd_build = Command_build(args);
                do_build(cmd_build);
            }

            do_run(cmd);
            break;
        }
    }
}

/* -----------------------------------------------------------------------------
Project-specific functions and types for CLI.

The idea is that each command in the program has its own Command_ struct, which
holds all the parameters. The constructors of these types parses the arguments
list, fetches the values and performs basic validation.

The command structs themselves don't perform any logic: they are plain old data
with a little bit of maintenance.

The command structs are public because external logic should use them directly
as sort-of-DTOs.
----------------------------------------------------------------------------- */

struct Command_init
{
    StrParam project_name = StrParam("name", "Name of the project", null);
    StrParam source_dir = StrParam("source", "Source code directory", "src");
    StrParam build_dir = StrParam("build", "Build directory", "build");
    StrParam generator = StrParam("generator", "CMake generator to use", "MinGW Makefiles");

    this(string[] args)
    {
        auto map = build_map(args);
        map.has_flag("help") ? help() : {};

        map.get_val(project_name).require();
        map.get_val(source_dir).require();
        map.get_val(build_dir).require();
        map.get_val(generator).require();
    }

    private void help()
    {
        writeln("init :: Initialize a new coal project\n");
        writeln(project_name.to_help());
        writeln(source_dir.to_help());
        writeln(build_dir.to_help());
        writeln(generator.to_help());
        exit(0);
    }
}

struct Command_add
{
    StrParam name = StrParam("name", "Name of the library", null);
    StrParam path = StrParam("path", "Full path to the root directory of the library", null);
    StrArrParam include = StrArrParam("include", "Include directories, relative to path", [
        ]);
    StrArrParam lib = StrArrParam("lib", "Library directories, relative to path", [
        ]);
    StrArrParam link = StrArrParam("link", "Link directives (without -L prefix)", [
        ]);
    StrArrParam dll = StrArrParam("dll", ".dll files relative to path, to copy when building for Windows", [
        ]);

    this(string[] args)
    {
        auto map = build_map(args);
        map.has_flag("help") ? help() : {};

        map.get_val(name).require();
        map.get_val(path).require();
        map.get_vals(include);
        map.get_vals(lib);
        map.get_vals(link);
        map.get_vals(dll);
    }

    private void help()
    {
        writeln("add :: Add a local library to the project as a soft link");
        writeln("The library files are not copied to this project (except for specified .DLLs)\n");
        writeln(name.to_help());
        writeln(path.to_help());
        writeln(include.to_help());
        writeln(lib.to_help());
        writeln(link.to_help());
        writeln(dll.to_help());
        exit(0);
    }
}

struct Command_build
{
    this(string[] args)
    {
    }

    private void help()
    {
        writeln("build :: Configure and build project using CMake");
        exit(0);
    }
}

struct Command_run
{
    FlagParam no_build = FlagParam("no-build", "Don't build project", false);
    string[] passthrough_params = [];

    this(string[] args)
    {
        auto map = build_map(args);
        map.has_flag("help") ? help() : {};

        map.get_flag(no_build).require();
        passthrough_params = map.get_delimited_params();
    }

    private void help()
    {
        writeln("run :: Run the project");
        writeln(no_build.to_help());
        exit(0);
    }
}

/* -----------------------------------------------------------------------------
General purpose functions and types for CLI.

Param is a generic parameter type that a command uses.
---------------------------------------------------------------------------- */

struct Param(T)
{
    string name;
    string desc;
    T value;

    this(string param_name, string description, T default_val)
    {
        name = param_name;
        desc = description;
        value = default_val;
    }

    /// Ensure the value is not null or empty. If it is, abort.
    void require() const
    {
        static if (is(T == string))
        {
            if (value is null || value.length == 0)
            {
                abort(format("Parameter --%s required (got empty string)", name));
            }
        }
        else static if (isDynamicArray!T || isStaticArray!T)
        {
            if (value is null || value.length == 0)
            {
                abort(format("Parameter --%s required (got empty list)", name));
            }
        }
    }

    /// Get a string explaining this parameter.
    string to_help() const
    {
        return format("--%s\n\tDescription: %s\n\tDefault:     %s\n", name, desc, to!(string)(value));
    }
}

alias StrParam = Param!(string);
alias StrArrParam = Param!(string[]);
alias FlagParam = Param!(bool);

private const PARAM_DELIMITER_KEY = "$PASS";

/// Build associative array from parameter list.
/// - A parameter is identified with `--param_name`.
/// - A parameter can have 0 or more values.
/// - A parameter with 0 values is implied to be a flag.
/// - To delimit parameters use `--`, all following params
/// are stored in a special value `PARAM_DELIMITER_KEY`.
///
/// In: `--param1 v1 v2 v3 --param2 --param3 v4 -- a --b`
/// Out: `[param1: [v1, v2, v3], param2: [], param3: [v4]], {PARAM_DELIMITER_KEY}: [a, --b]`
///
/// Params:
///   args = Command line args **WITHOUT** the first two elements (program name and command).
private string[][string] build_map(string[] args)
{
    string curr_key = "";
    string[][string] map = null;

    foreach (size_t i, const ref string s; args)
    {
        if (s.startsWith("--"))
        {
            curr_key = s[2 .. $];

            // If you specify only -- then the rest of the args should
            // be passed to the next process (if needed).
            if (curr_key == "")
            {
                map[PARAM_DELIMITER_KEY] = args[i + 1 .. $];
                break;
            }

            if (curr_key == PARAM_DELIMITER_KEY)
            {
                writefln("Error: keyword %s is reserved", PARAM_DELIMITER_KEY);
                continue;
            }

            if (curr_key in map)
            {
                writeln("Error: parameter " ~ curr_key ~ " already defined!");
                return null;
            }
            map[curr_key] = [];
            continue;
        }
        map[curr_key] ~= s;
    }

    return map;
}

unittest
{
    auto map = build_map([
        "--param_list", "v1", "v2", "v3",
        "--param", "v",
        "--flag",
        "--", "a", "--b", "c", "--d"
    ]);
    assert(map.get_vals("param_list", []) == ["v1", "v2", "v3"]);
    assert(map.get_val("param", null) == "v");
    assert(map.has_flag("flag"));
    assert(map.get_delimited_params() == ["a", "--b", "c", "--d"]);
}

noreturn abort(string error)
{
    writeln(error);
    exit(1);
}

noreturn abort_param_required(string param)
{
    abort("Parameter --" ~ param ~ " required");
}

private string get_val(ref string[][string] map, string key, string def)
{
    if (key in map)
    {
        auto values = map[key];
        if (values.length == 0)
        {
            return def;
        }
        if (values.length > 1)
        {
            abort(format("Parameter --%s expecting 1 value, got %d", key, values.length));
        }

        return values[0];
    }
    return def;
}

private string[] get_vals(ref string[][string] map, string key, string[] def)
{
    if (key in map)
    {
        return map[key];
    }
    return def;
}

private bool has_flag(ref string[][string] map, string key)
{
    if (key in map)
    {
        return true;
    }
    return false;
}

private ref StrParam get_val(ref string[][string] map, ref StrParam param)
{
    param.value = map.get_val(param.name, param.value);

    // We return the reference itself to allow chaining.
    return param;
}

private ref StrArrParam get_vals(ref string[][string] map, ref StrArrParam param)
{
    param.value = map.get_vals(param.name, param.value);

    // We return the reference itself to allow chaining.
    return param;
}

private ref FlagParam get_flag(ref string[][string] map, ref FlagParam param)
{
    param.value = map.has_flag(param.name);

    // We return the reference itself to allow chaining.
    return param;
}

private string[] get_delimited_params(ref string[][string] map)
{
    if (PARAM_DELIMITER_KEY in map)
    {
        return map[PARAM_DELIMITER_KEY];
    }
    return [];
}
