import std.stdio;
import std.string;
import std.algorithm.searching;
import core.stdc.stdlib;
import std.format;
import std.traits;

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
            writeln("Unknown command\nUse coal --help for a list of commands");
            break;
        }
    case "init":
        {
            import init;

            Command_init cmd = Command_init(args);
            do_init(cmd);
            break;
        }
    }
}

/* -----------------------------------------------------------------------------
General purpose functions and types for CLI.

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
        writeln("init -- Initialize a new coal project\n");
        writeln(project_name.to_help());
        writeln(source_dir.to_help());
        writeln(build_dir.to_help());
        writeln(generator.to_help());
        exit(0);
    }
}

struct Command_add
{
}

struct Command_build
{
}

struct Command_run
{
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
        const string default_value = value == null ? "[None] (required)" : value;
        return format("--%s\n\tDescription: %s\n\tDefault:    %s\n", name, desc, default_value);
    }
}

alias StrParam = Param!(string);

/// Build associative array from parameter list.
///
/// In: `--param1 v1 v2 v3 --param2 --param3 v4`
/// Out: `[param1: [v1, v2, v3], param2: [], param3: [v4]]`
///
/// Params:
///   args = Command line args **WITHOUT** the first two elements (program name and command).
private string[][string] build_map(ref string[] args)
{
    string curr_key = "";
    string[][string] map = null;

    foreach (const ref string s; args)
    {
        if (s.startsWith("--"))
        {
            curr_key = s[2 .. $];

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
