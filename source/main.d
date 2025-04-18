import std.stdio;
import std.conv;
import init;
import add;
import input;
import build;
import std.json;

enum Command { init, build, run, add }
Command cmd;

void main(string[] args)
{
	if (args.length < 2) {
		return;
	}

	string command = args[1];

	if (command == "init") {
		cmd = Command.init;
	} else if (command == "build") {
		cmd = Command.build;
	} else if (command == "run") {
		cmd = Command.run;
	} else if (command == "add") {
		cmd = Command.add;
	} else {
		writeln("Unknown command");
		return;
	}

	if (cmd == Command.init) {
		do_init();
	}
	else if (cmd == Command.add) {
		do_add();
	}
	else if (cmd == Command.build) {
		do_build();
	}
	else if (cmd == Command.run) {
		do_build();
		do_just_run();
	}
}