import std.stdio;
import std.string;
import std.path;
import std.file;
import std.regex;
import clyd.color;

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
