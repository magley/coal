import project;
import input;
import coalfile;
import cli;
import core.stdc.stdlib;
import std.algorithm;
import std.stdio;

void do_add(ref Command_add cmd)
{
	Project p = load();

	if (p.libs.any!(l => l.name == cmd.name.get))
	{
		writefln("A library by the name of %s is already defined", cmd.name.get);
		exit(1);
	}

	Library lib = Library();
	lib.name = cmd.name.get;
	lib.path = cmd.path.get;
	lib.include_dirs = cmd.include.get;
	lib.lib_dirs = cmd.lib.get;
	lib.link_libs = cmd.link.get;
	lib.dll_dirs = cmd.dll.get;

	p.libs ~= lib;
	save(p);
}
