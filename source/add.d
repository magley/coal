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
		writeln(
			CERR ~ "Library " ~ CFOCUS ~ cmd.name.get ~ CERR ~ " already defined for project " ~ CFOCUS ~ p.name ~ CCLEAR);
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
