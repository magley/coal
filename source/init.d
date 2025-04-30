import project;
import input;
import coalfile;
import core.stdc.stdlib;
import std.file;
import std.path;
import std.stdio;
import clyd.command;

Project do_init(Command cmd_init)
{
	return do_init(
		cmd_init.args["name"].value,
		cmd_init.args["src"].value,
		cmd_init.args["build"].value,
		cmd_init.args["generator"].value,
	);
}

Project do_init(string name, string source_dir, string build_dir, string generator)
{
	Project p = new Project();
	p.name = name;
	p.source_dirs = [source_dir];
	p.build_dir = build_dir;
	p.generator = generator;
	p.libs = [];

	save(p);
	create_stub(p);

	return p;
}

private void create_stub(Project p)
{
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
}
