import project;
import input;
import coalfile;
import core.stdc.stdlib;
import std.file;
import std.path;
import std.stdio;

void do_init()
{
	Project p = new Project();

	p.name = input_safe("Project name");
	p.source_dirs = [input_non_empty("Source code directory")];
	p.build_dir = input_non_empty("Build directory");
	p.generator = "MinGW Makefiles";
	p.libs = [];

	save(p);
	create_stub(p);
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
			file.writeln("#include <iostream>\n");
			file.writeln("int main(int argc, char** argv)");
			file.writeln("{\n\tstd::cout << \"Hello World\\n\";\n}");
			file.close();
		}
	}
}
