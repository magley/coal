import project;
import input;
import coalfile;
import core.stdc.stdlib;
import std.file;
import std.path;
import std.stdio;
import cli;

Project do_init(const ref Command_init cmd)
{
	return do_init(cmd.project_name.get, cmd.source_dir.get, cmd.build_dir.get, cmd.generator.get);
}

Project do_init(const ref Command_template_spawn cmd)
{
	return do_init(
		cmd.project_name.get_strict,
		cmd.source_dir.get_strict,
		cmd.build_dir.get_strict,
		cmd.generator.get_strict
	);
}

private Project do_init(string name, string source_dir, string build_dir, string generator)
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
			file.writeln("#include <iostream>\n");
			file.writeln("int main(int argc, char** argv)");
			file.writeln("{\n");
			file.writeln("\n\tstd::cout << \"Hello World\\n\";\n");
			file.writeln("\n\treturn 0;\n");
			file.writeln("}");

			file.close();
		}
	}
}
