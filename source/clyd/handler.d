module clyd.handler;

import std.array;
import std.algorithm;
import std.stdio;
import core.stdc.stdlib;
import clyd.arg;
import clyd.command;

/// 
/// Params:
///   root = The root command of the program.
///   args = Arguments provided by the program's entry point (`main()`).
void handle(Command root, string[] args)
{
    // [1] Ignore 0th command-line arg (program name).

    args = args[1 .. $];

    // [2] Split _commands_ from _arguments_ in `args`.

    string[] commands = [root.name];
    {
        size_t k = 0;
        for (; k < args.length; k++)
        {
            string a = args[k];

            if (a.startsWith("-"))
            {
                break;
            }
            commands ~= a;
        }
        args = args[k .. $];
    }

    // [3] Determine which command to run based on `commands`.

    Command[] chain;
    chain ~= root;

    for (size_t i = 1; i < commands.length; i++) // Start from 1 because [0] is root cmd which we ignore
    {
        string subcommand_name = commands[i];
        Command most_recent_command = chain.back;

        if (subcommand_name in most_recent_command.subcmd)
        {
            Command subcommand = most_recent_command.subcmd[subcommand_name];
            chain ~= subcommand;
        }
        else
        {
            import input;

            writefln(
                CERR ~ "Unknown command "
                    ~ CFOCUS ~ subcommand_name
                    ~ CERR ~ " in "
                    ~ CFOCUS ~ commands.join(
                        " "));
            writeln();
            writefln(
                CINFO ~ "Type "
                    ~ CFOCUS ~ commands[0 .. $ - 1].join(
                        " ") ~ " --help"
                    ~ CINFO ~ " for a list of commands"
                    ~ CCLEAR
            );

            exit(1);
        }
    }

    // [4] Invoke command.

    Command command = chain.back;
    command.invoke(args);
}
