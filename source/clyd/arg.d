module clyd.arg;

import std.conv;
import std.string;
import std.array;
import std.stdio;
import core.stdc.stdlib;
import std.algorithm;
import clyd.exception;

class Arg
{
    enum Type
    {
        Single,
        Multiple,
        Flag
    }

    string name;
    string desc;
    string shorthand;
    string[] values_;
    Type type;

    /// Construct argument which accepts a single string value.
    /// Params:
    ///   name = Argument name. Used in program as --{name}
    ///   shorthand = Shorthand name (optional). Used in program as -{shorthand}
    ///   desc = Argument description, shown in help menus.
    ///   default_value = Default value for an argument, if none is specified.
    static Arg single(string name, string shorthand, string desc, string default_value)
    {
        Arg a = new Arg();
        a.name = name;
        a.shorthand = shorthand;
        a.desc = desc;
        a.values_ = [default_value];
        a.type = Type.Single;
        return a;
    }

    /// Construct argument which accepts an ordered sequence of string values.
    /// Params:
    ///   name = Argument name. Used in program as --{name}
    ///   shorthand = Shorthand name (optional). Used in program as -{shorthand}
    ///   desc = Argument description, shown in help menus.
    ///   default_value = Default value for an argument, if none is specified.
    static Arg multiple(string name, string shorthand, string desc, string[] default_value)
    {
        Arg a = new Arg();
        a.name = name;
        a.shorthand = shorthand;
        a.desc = desc;
        a.values_ = default_value;
        a.type = Type.Multiple;
        return a;
    }

    /// Construct argument which represents a flag.
    /// Params:
    ///   name = Argument name. Used in program as --{name}
    ///   shorthand = Shorthand name (optional). Used in program as -{shorthand}
    ///   desc = Argument description, shown in help menus.
    ///   default_value = Default value for an argument, if none is specified.
    static Arg flag(string name, string shorthand, string desc, bool default_value)
    {
        Arg a = new Arg();
        a.name = name;
        a.shorthand = shorthand;
        a.desc = desc;
        a.values_ = default_value ? [""] : [];
        a.type = Type.Flag;
        return a;
    }

    /// Returns: The singular value of the argument as a string.
    /// Throws: On type mismatch or invalid value.
    string value()
    {
        if (type != Type.Single)
        {
            throw new ArgException(name, "Bad type");
        }
        if (values_.length > 1)
        {
            throw new ArgException(name, "Too many values (expected 1)");
        }
        if (values_.length == 0)
        {
            throw new ArgMissingValueException(name);
        }
        if (values_[0] == null)
        {
            throw new ArgMissingValueException(name);
        }
        return values_[0];
    }

    /// Params:
    ///   fallback = Value which to return if the parameter is not defined 
    /// Returns: The singular value of the argument as a string.
    /// Throws: On type mismatch or invalid value.
    string value_or(string fallback)
    {
        try
        {
            return value();
        }
        catch (ArgMissingValueException e)
        {
            return fallback;
        }
    }

    /// Returns: Values as a sequence of strings for this argument.
    /// Throws: On type mismatch or invalid value.
    string[] values()
    {
        if (type != Type.Multiple)
        {
            throw new ArgException(name, "Bad type");
        }
        return values_;
    }

    /// Returns: `true` if the flag has been set.
    /// Throws: On type mismatch or invalid value.
    bool is_set_flag()
    {
        if (type != Type.Flag)
        {
            throw new ArgException(name, "Bad type");
        }
        return values_.length != 0;
    }
}
