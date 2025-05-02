module clyd.exception;

import std.format;

class ArgException : Exception
{
    string arg;
    string msg;
    this(string arg, string msg)
    {
        this.arg = arg;
        this.msg = msg;
        super(format("%s: %s", arg, msg));
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
