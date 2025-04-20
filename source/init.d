import project;
import input;
import coalfile;

void do_init()
{
	Project p = new Project();

	p.name = input_safe("Project name");
	p.source_dirs = [input_non_empty("Source code directory")];
	p.build_dir = input_non_empty("Build directory");
	p.generator = "MinGW Makefiles";
	p.libs = [];

	save(p);
}
