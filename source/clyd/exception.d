module clyd.exception;

import std.format;

class ArgException : Exception
{
    this(string arg, string message)
    {
        super(format("%s: %s", arg, message));
    }
}

class ArgRequiredException : ArgException
{
    this(string arg)
    {
        super(arg, "Missing argument");
    }
}

class ArgMissingValueException : ArgException
{
    this(string arg)
    {
        super(arg, "Missing value for argument");
    }

}
