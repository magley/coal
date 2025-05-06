import project;
import clyd.color;
import coalfile;
import core.stdc.stdlib;
import std.algorithm;
import std.stdio;
import clyd.command;

void do_add(Command cmd)
{
	string name = cmd.args["name"].value;
	string path = cmd.args["path"].value;
	string[] include_dirs = cmd.args["include"].values;
	string[] lib_dirs = cmd.args["lib"].values;
	string[] link_libs = cmd.args["link"].values;
	string[] dll_dirs = cmd.args["dll"].values;

	Project p = load();

	if (p.libs.any!(l => l.name == name))
	{
		writeln(
			CERR ~ "Library " ~ CFOCUS ~ name ~ CERR ~ " already defined for project " ~ CFOCUS ~ p.name ~ CCLEAR);
		exit(1);
	}

	Library lib = Library();
	lib.name = name;
	lib.path = path;
	lib.include_dirs = include_dirs;
	lib.lib_dirs = lib_dirs;
	lib.link_libs = link_libs;
	lib.dll_dirs = dll_dirs;

	p.libs ~= lib;
	save(p);

}
