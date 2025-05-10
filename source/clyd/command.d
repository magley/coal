module clyd.command;

import std.conv;
import std.string;
import std.array;
import std.stdio;
import core.stdc.stdlib;
import std.algorithm;
import clyd.exception;
import clyd.arg;
import clyd.color;

alias CommandCallback = void function(Command self);

class Command
{
    private static const PARAM_DELIMITER_KEY = "$PASS";

    string name;
    string desc;
    Command[string] subcmd;
    Command supercmd;
    Arg[string] args;
    CommandCallback callback;

    this(string name, string desc)
    {
        this.name = name;
        this.desc = desc;
        this.subcmd = null;
        this.supercmd = null;
        this.callback = null;
    }

    string[] command_chain() const
    {
        if (supercmd !is null)
        {
            return supercmd.command_chain() ~ name;
        }
        return [name];
    }

    /// Add subcommand to this command.
    /// Returns: `this` 
    Command subcommand(Command cmd)
    {
        subcmd[cmd.name] = cmd;
        cmd.supercmd = this;
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
                string full_name = command_chain().join(" ");
                writefln(CERR ~ "No callback defined for command " ~ CFOCUS ~ "%s\n", full_name);
                writefln(
                    CCLEAR ~ "If you are the developer of this program, declare a callback function");
                writefln(CINFO ~ "    cmd = new Command(\"%s\", [...]);", name);
                writefln(CINFO ~ "    cmd.set_callback(&func);");
                writeln();
                writefln(CCLEAR ~ "If you are a user of this program, notify the developer");
                writefln("=======================================================");
                writeln(CCLEAR);

                help();
                exit(1);
            }

            callback(this);
        }
        catch (ArgException e)
        {
            writefln(CERR ~ "Error " ~ CINFO ~ "handling argument " ~ CFOCUS ~ "%s: " ~ CERR ~ "%s" ~ CCLEAR, e.arg, e
                    .msg);
            exit(1);
        }
    }

    /// Show help.
    private void help()
    {
        string name_chained = command_chain.join(" ");
        writefln(""
                ~ CINFO ~ "USAGE: "
                ~ CFOCUS ~ "%s "
                ~ CINFO ~ "["
                ~ CTRACE ~ "--help"
                ~ CINFO ~ "] "
                ~ CINFO ~ "["
                ~ CTRACE ~ "<command>"
                ~ CINFO ~ "] "
                ~ CINFO ~ "["
                ~ CTRACE ~ "<options...>"
                ~ CINFO ~ "] "
                ~ CINFO ~ "["
                ~ CTRACE ~ "-- [<application arguments...>]"
                ~ CINFO ~ "]", name_chained
        );
        writeln();
        writeln(CINFO ~ desc);
        writeln();

        if (args.length > 0)
        {
            const int SPACING = 3;

            ulong w_shorthand = unique_args.map!(a => a.shorthand.length).maxElement();
            w_shorthand += "-".length;
            w_shorthand += SPACING;

            ulong w_name = unique_args.map!(a => a.name.length).maxElement();
            w_name += "--".length;
            w_name += SPACING;

            writeln(CCLEAR ~ "Options");
            writeln(CCLEAR ~ "=======");
            writeln();
            foreach (arg; unique_args)
            {
                string shorthand_flag = arg.shorthand != null ? ("-" ~ arg.shorthand) : "";
                string flag = ("--" ~ arg.name);
                writefln("  " ~ CTRACE ~ "%-*s" ~ CFOCUS ~ "%-*s" ~ CINFO ~ "%s",
                    w_shorthand, shorthand_flag,
                    w_name, flag,
                    arg.desc
                );
            }
            writeln();
        }

        if (subcmd.length > 0)
        {
            const int SPACING = 3;

            ulong w_cmdname = subcmd.values.map!(cmd => cmd.name.length).maxElement();
            w_cmdname += SPACING;

            writeln(CCLEAR ~ "Subcommands");
            writeln(CCLEAR ~ "===========");
            writeln();
            foreach (cmd; subcmd)
            {
                writefln("  " ~ CFOCUS ~ "%-*s" ~ CINFO ~ "%s",
                    w_cmdname, cmd.name,
                    cmd.desc,
                );
            }
            writeln();
        }

        write(CCLEAR);
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
                writefln(
                    CERR ~ "Unknown command line flag "
                        ~ CFOCUS ~ key);
                writeln();
                const string name_chained = command_chain.join(" ");
                writefln(
                    CINFO ~ "Type "
                        ~ CFOCUS ~ name_chained ~ " --help"
                        ~ CINFO ~ " for a list of supported flags"
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
