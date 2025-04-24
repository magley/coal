import project;
import input;
import coalfile;
import cli;

void do_add(ref Command_add cmd)
{
	Project p = load();

	Library lib = Library();
	lib.name = cmd.name.value;
	lib.path = cmd.path.value;
	lib.include_dirs = cmd.include.value;
	lib.lib_dirs = cmd.lib.value;
	lib.link_libs = cmd.link.value;
	lib.dll_dirs = cmd.dll.value;

	p.libs ~= lib;
	save(p);
}
