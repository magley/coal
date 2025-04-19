import std.stdio;
import std.string;
import std.path;
import std.file;

void do_prompt(string s)
{
	writef("%s: ", s);
}

private string gets_dir_or_empty(string prompt)
{
	string s = input(prompt);
	s = s.strip();

	if (!exists(s))
	{
		writeln(format("'%s' is not a valid path", s));
		return "";
	}
	if (!isDir(s))
	{
		writeln(format("'%s' is not a directory", s));
		return "";
	}

	return replace(s, "\\", "/");
}

string input(string prompt)
{
	do_prompt(prompt);
	return readln();
}

string input_non_empty(string prompt)
{
	string s = "";

	while (s == "")
	{
		s = input(prompt);
		s = s.strip();
	}

	return s;
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

string[] input_multiple(string prompt, string prompt_single)
{
	do_prompt(prompt);
	writeln();

	string[] result = [];

	while (true)
	{
		string s = input(prompt_single);
		s = s.strip();

		if (s == "")
		{
			if (result.length == 0)
			{
				continue;
			}
			else
			{
				break;
			}
		}
		else
		{
			result ~= s;
		}
	}

	return result;
}

string[] input_multiple_or_none(string prompt, string prompt_single)
{
	do_prompt(prompt);
	writeln();

	string[] result = [];

	while (true)
	{
		string s = input(prompt_single);
		s = s.strip();

		if (s == "")
		{
			break;
		}
		else
		{
			result ~= s;
		}
	}

	return result;
}

string[] input_dir_multiple_or_none(string prompt, string prompt_single)
{
	do_prompt(prompt);
	writeln();

	string[] result = [];

	while (true)
	{
		string s = gets_dir_or_empty(prompt);

		if (s == "")
		{
			break;
		}
		else
		{
			result ~= s;
		}
	}

	return result;
}
