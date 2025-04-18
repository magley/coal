import project;
import input;
import coalfile;

void do_add() {
	Project p = load();

	Library lib = Library();
	lib.name = input_non_empty("Library name");
	lib.path = input_non_empty("Library full path");
	lib.include_dirs = input_dir_multiple_or_none("Include directories", "Relative include/ dir");
	lib.lib_dirs = input_dir_multiple_or_none("Library directories", "Relative lib/ dir");
	lib.link_libs = input_multiple_or_none("Linker directives (without -L)", "Link directive");
	lib.dll_dirs = input_dir_multiple_or_none("DLL files", "Path to .dll file");

	p.libs ~= lib;
	save(p);
}