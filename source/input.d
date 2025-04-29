import std.stdio;
import std.string;
import std.path;
import std.file;
import std.regex;

const CERR = "\033[0;31m";
const CWARN = "\033[0;33m";
const CINFO = "\033[0;90m";
const CFOCUS = "\033[0;32m";
const CCLEAR = "\033[0;37m";
const CTRACE = "\033[0;34m";

private string gets_dir_or_empty(string prompt)
{
	writef(prompt ~ ": ");
	string s = readln();
	s = s.strip();

	if (!exists(s))
	{
		writefln(CFOCUS ~ "%s" ~ CWARN ~ " is not a valid path" ~ CCLEAR, s);
		return "";
	}
	if (!isDir(s))
	{
		writefln(CFOCUS ~ "%s" ~ CWARN ~ " is not a directory" ~ CCLEAR, s);
		return "";
	}

	return replace(s, "\\", "/");
}

string input_dir_non_empty(string prompt)
{
	string s = "";

	while (s == "")
	{
		s = gets_dir_or_empty(prompt);
	}

	return s;
}
