import std.stdio;
import std.string;
import std.path;
import std.file;
import std.regex;

static CERR = "\033[0;31m";
static CWARN = "\033[0;33m";
static CINFO = "\033[0;90m";
static CFOCUS = "\033[0;32m";
static CCLEAR = "\033[0;37m";
static CTRACE = "\033[0;34m";

void toggle_color(ref string[] args, string this_program_no_color_env_var_name = "${PROGNAME}_NO_COLOR")
{
	if (this_program_no_color_env_var_name == "${PROGNAME}_NO_COLOR")
	{
		this_program_no_color_env_var_name = "";
	}

	if (!should_use_color(args, this_program_no_color_env_var_name))
	{
		CERR = "";
		CWARN = "";
		CINFO = "";
		CFOCUS = "";
		CCLEAR = "";
		CTRACE = "";
	}
}

bool should_use_color(ref string[] args, string this_program_no_color_env_var_name)
{
	import std.process;
	import std.array;
	import std.algorithm;

	auto var_no_color = environment.get("NO_COLOR");
	if (var_no_color !is null && var_no_color != "")
	{
		return false;
	}

	auto var_term = environment.get("TERM");
	if (var_term == "dumb")
	{
		return false;
	}

	if (args.canFind("--no-color"))
	{
		// HACK: clyd will complain if it find a `--no-color` flag in any of the
		// commands, so we remove it first. 
		args = args.remove(args.countUntil("--no-color"));

		return false;
	}

	if (this_program_no_color_env_var_name != "")
	{
		auto var_program_specific = environment.get(this_program_no_color_env_var_name);
		if (var_program_specific !is null && var_program_specific != "")
		{
			return false;
		}
	}

	return true;
}

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
