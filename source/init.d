import project;
import clyd.color;
import coalfile;
import core.stdc.stdlib;
import std.file;
import std.path;
import std.stdio;
import clyd.command;

Project do_init_new(Command cmd_init)
{
	Project p = create_new_project(cmd_init);
	save(p);
	create_stub(p);
	after_init(p.name);

	return p;
}

Project create_new_project(Command cmd_init)
{
	Project p = create_new_project(
		cmd_init.args["name"].value,
		cmd_init.args["src"].value,
		cmd_init.args["build"].value,
		cmd_init.args["generator"].value,
	);

	return p;
}

void after_init(string project_name)
{
	writefln("Initialized "
			~ CFOCUS ~ project_name
			~ CCLEAR ~ "\nBuild the project with "
			~ CFOCUS ~ "coal build"
			~ CCLEAR ~ " or run the project with "
			~ CFOCUS ~ "coal run"
			~ CCLEAR);
}

private Project create_new_project(string name, string source_dir, string build_dir, string generator)
{
	ensure_coalfile_not_exists();

	Project p = new Project();
	p.name = name;
	p.source_dirs = [source_dir];
	p.build_dir = build_dir;
	p.generator = generator;
	p.libs = [];

	return p;
}

void create_stub(Project p)
{
	string dir = buildPath(".", p.source_dirs[0]);
	if (!exists(dir))
	{
		mkdir(dir);

		string fname_main = buildPath(dir, "main.cpp");
		File file = File(fname_main, "w");
		file.writeln("#include <iostream>");
		file.writeln("int main(int argc, char** argv)");
		file.writeln("{");
		file.writeln("\tstd::cout << \"Hello World\\n\";");
		file.writeln("\treturn 0;");
		file.writeln("}");

		file.close();
	}
}
