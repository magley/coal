module clyd.command;

import std.conv;
import std.string;
import std.array;
import std.stdio;
import core.stdc.stdlib;
import std.algorithm;
import clyd.exception;
import clyd.arg;

alias CommandCallback = void function(Command self);

class Command
{
    private static const PARAM_DELIMITER_KEY = "$PASS";

    string name;
    string desc;
    Command[string] subcmd;
    Arg[string] args;
    CommandCallback callback;

    this(string name, string desc)
    {
        this.name = name;
        this.desc = desc;
        this.subcmd = null;
        this.callback = null;
    }

    /// Add subcommand to this command.
    /// Returns: `this` 
    Command subcommand(Command cmd)
    {
        subcmd[cmd.name] = cmd;
        return this;
    }

    /// Add argument to this command.
    /// Returns: `this` 
    Command arg(Arg arg)
    {
        args[arg.name] = arg;
        if (arg.shorthand != null && arg.shorthand != "")
        {
            args[arg.shorthand] = arg;
        }
        return this;
    }

    /// Specify the callback function invoked when this command is executed.
    /// Returns: `this` 
    Command set_callback(CommandCallback cb)
    {
        this.callback = cb;
        return this;
    }

    ///
    /// Returns: Arguments which are not processed by this program and are meant to be passed to the program invoked by this one.
    /// Example: When this command is invoked with arguments `--foo bar -- -a -b --baz bat`, it will return `['-a', '-b', '--baz', 'bat']`.
    string[] get_application_arguments()
    {
        if (Command.PARAM_DELIMITER_KEY in args)
        {
            return args[PARAM_DELIMITER_KEY].values;
        }
        return [];
    }

    /// Run command with the provided arguments.
    /// Params:
    ///   args = Command line args from the shell EXCLUDING program name (the first one). 
    package void invoke(string[] args)
    {
        try
        {
            feed_args(build_map(args));

            if ("help" in this.args)
            {
                help();
                exit(0);
            }

            if (callback == null)
            {
                // TODO: Maybe invoke help by default? Or specify what's going on?
                writeln("No callback defined for command " ~ name);
                exit(1);
            }

            callback(this);
        }
        catch (ArgException e)
        {
            // TODO: Nicer output. Have to split arg name and arg message for colors.
            writeln(e.message);
            exit(1);
        }
    }

    /// Show help.
    private void help()
    {
        // TODO: Show supercommands as well. So it would be `coal template add` instead of `add`.
        writefln("USAGE: %s [--help] [<command>] [<options...>] [-- [<application arguments...>]]", name);
        writeln();
        writeln(desc);
        writeln();

        // TODO: Alignment doesn't work properly.

        if (args.length > 0)
        {
            writeln("Options");
            writeln("=======");
            writeln();
            foreach (arg; unique_args)
            {
                string shorthand_flag = arg.shorthand != null ? ("-" ~ arg.shorthand) : "";
                string flag = ("--" ~ arg.name);
                writefln("%s\t%s\t\t%s", shorthand_flag, flag, arg.desc);
            }
            writeln();
        }

        if (subcmd.length > 0)
        {
            writeln("Subcommands");
            writeln("===========");
            writeln();
            foreach (cmd; subcmd)
            {
                writefln("\t%s\t\t%s", cmd.name, cmd.desc);
            }
            writeln();
        }
    }

    /// Returns: List of unique arguments (removing duplicates caused by shorthand argument names).
    private Arg[] unique_args()
    {
        Arg[string] result;

        foreach (arg; args)
        {
            if (arg.name !in result)
            {
                result[arg.name] = arg;
            }
        }

        return result.values;
    }

    private void feed_args(string[][string] map)
    {
        foreach (string key, string[] value; map)
        {
            if (key == PARAM_DELIMITER_KEY)
            {
                // HACK: This is basically hardcoding the help argument to the command.
                // It's not a huge deal, but it may not be desireable behavior.

                args[PARAM_DELIMITER_KEY] = Arg.multiple(PARAM_DELIMITER_KEY, null, null, map[PARAM_DELIMITER_KEY]);
                continue;
            }
            if (key == "help")
            {
                // HACK: Ditto

                args["help"] = Arg.flag("help", null, "Show this help menu", false);
                continue;
            }

            if (key !in args)
            {
                import input;

                writefln(
                    CERR ~ "Unknown argument "
                        ~ CFOCUS ~ key);
                writeln();
                // TODO: We want to do full command chain here.
                writefln(
                    CINFO ~ "Use "
                        ~ CFOCUS ~ "--help"
                        ~ CINFO ~ " for a list of commands"
                        ~ CCLEAR
                );

                exit(1);
            }

            Arg arg = args[key];

            final switch (arg.type)
            {
            case Arg.Type.Single:
                {
                    // (if value.length > 1) is not done here, because
                    // Arg::value() will catch that.
                    arg.values_ = value;
                }
                break;
            case Arg.Type.Multiple:
                {
                    arg.values_ = value;
                }
                break;
            case Arg.Type.Flag:
                {
                    arg.values_ = [""];
                }
                break;

            }
        }
    }

    private string[][string] build_map(string[] args)
    {
        string curr_key = "";
        string[][string] map = null;

        foreach (size_t i, const ref string s; args)
        {
            if (s.startsWith("-"))
            {
                if (s.startsWith("--"))
                {
                    curr_key = s[2 .. $];
                }
                else
                {
                    curr_key = s[1 .. $];
                }

                // If you specify only -- then the rest of the args should
                // be passed to the next process (if needed).
                if (s == "--")
                {
                    map[PARAM_DELIMITER_KEY] = args[i + 1 .. $];
                    break;
                }

                if (curr_key == PARAM_DELIMITER_KEY)
                {
                    exit(1);
                    continue;
                }

                if (curr_key in map)
                {
                    exit(1);
                    return null;
                }
                map[curr_key] = [];
                continue;
            }
            map[curr_key] ~= s;
        }

        return map;
    }
}
