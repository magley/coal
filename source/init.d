import project;
import input;
import coalfile;
import core.stdc.stdlib;
import std.file;
import std.path;
import std.stdio;
import cli;

void do_init(ref Command_init cmd)
{
	Project p = new Project();
	p.name = cmd.project_name.value;
	p.source_dirs = [cmd.source_dir.value];
	p.build_dir = cmd.build_dir.value;
	p.generator = cmd.generator.value;
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
