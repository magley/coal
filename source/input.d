// Utility functions for user input.

import std.stdio;
import std.string;

void do_prompt(string s) {
	writef("%s: ", s);
}

string input(string prompt) {
	do_prompt(prompt);
	return readln();
}

string input_non_empty(string prompt) {
	string s = "";

	while (s == "") {
		s = input(prompt);
		s = s.strip();
	}

	return s;
}

string input_dir_non_empty(string prompt) {
	string s = "";

	while (s == "") {
		s = input(prompt);
		s = s.strip();
		s = replace(s, "\\", "/");
	}

	return s;
}

string[] input_multiple(string prompt, string prompt_single) {
	do_prompt(prompt);
	writeln();

	string[] result = [];

	while (true) {
		string s = input(prompt_single);
		s = s.strip();

		if (s == "") {
			if (result.length == 0) {
				continue;
			} else {
				break;
			}
		} else {
			result ~= s;
		}
	}

	return result;
}

string[] input_multiple_or_none(string prompt, string prompt_single) {
	do_prompt(prompt);
	writeln();

	string[] result = [];

	while (true) {
		string s = input(prompt_single);
		s = s.strip();

		if (s == "") {
			break;
		} else {
			result ~= s;
		}
	}

	return result;
}

string[] input_dir_multiple_or_none(string prompt, string prompt_single) {
	do_prompt(prompt);
	writeln();

	string[] result = [];

	while (true) {
		string s = input(prompt_single);
		s = s.strip();
		s = replace(s, "\\", "/");

		if (s == "") {
			break;
		} else {
			result ~= s;
		}
	}

	return result;
}