import clyd.command;
import clyd.handler;
import clyd.arg;
import clyd.color;

import init;
import add;
import build;
import templates;
import clean;
import config;

const VERSION = "0.7-beta";

void main(string[] args)
{
	Command root = new Command("coal", "Coal version " ~ VERSION)
		.subcommand(
			new Command("init", "Initialize a new project")
				.arg(Arg.single("name", "n", "Project name", null))
				.arg(Arg.single("src", "s", "Source code directory (relative)", "src/"))
				.arg(Arg.single("build", "b", "Binaries directory (relative)", "build/"))
				.arg(Arg.single("generator", "g", "Which CMake generator to use", "MinGW Makefiles"))
				.arg(Arg.single("cmake-ver-min", null, "Minimum supported CMake min version", "3.15"))
				.arg(Arg.single("cmake-ver-max", null, "Maximum supported CMake min version", "4.0"))
				.arg(Arg.single("cpp", null, "C++ version standard", "14", CPP_ALLOWED_VERSIONS_STR))
				.set_longer_desc(
					"This command will create a new coal project.\n\n" ~
					"If you're initializing in an empty folder, coal\n" ~
					"will generate a basic Hello World project to get\n" ~
					"you started.\n\n" ~
					"If you're initializing in a directory which has\n" ~
					"a C++ project, it won't create additional files.\n" ~
					"Coal assumes a C++ project exists in the directory\n" ~
					"if it contains a folder with the same name as the\n" ~
					CFOCUS ~ "src" ~ CCLEAR ~ " parameter provded when executing this command.\n\n" ~
					"This command does not generate binaries or CMake files.\n\n" ~
					"Example:\n" ~
					CTRACE ~ "\tcoal init --name \"my_new_project\" --src \"source\"\n" ~ CCLEAR ~
					"\tThis will create a project " ~ CFOCUS ~ "my_new_project" ~ CCLEAR ~ "\n" ~
					"\twhose source files will be located in " ~ CFOCUS ~ "source/" ~ CCLEAR
				)
				.set_callback((Command cmd) { do_init_new(cmd); })
		)
		.subcommand(
			new Command("add", "Add local library as dependency to project")
				.arg(Arg.single("name", "n", "Name of library", null))
				.arg(Arg.single("path", "p", "Full path to root of library", null))
				.arg(Arg.multiple("include", "i", "Include directories", []))
				.arg(Arg.multiple("source", "s", "Source files and dirs", []))
				.arg(Arg.multiple("lib", "l", "Library directories", []))
				.arg(Arg.multiple("link", "L", "Link directives", []))
				.arg(Arg.multiple("dll", null, "DLL files to copy", []))
				.set_longer_desc(
					"This command adds a local dependency to the project.\n\n" ~
					"If you have a compatible C++ library on your computer,\n" ~
					"you may add it as a soft link to the project.\n\n" ~
					"Being a soft link, the library files are not copied\n" ~
					"to the project folder. Furthermore, removing the\n" ~
					"dependency files will cause issues when building\n" ~
					"the project.\n\n" ~
					"A dependency requires the full path to its files,\n" ~
					"which is used as a root path when computing any\n" ~
					"other directories that are added into the project.\n" ~
					"What that means is that parameters like " ~ CFOCUS ~ "include\n"
					~ CCLEAR ~ "must be relative to the path of the dependency.\n\n" ~
					"The full path to the dependency is stored in the\n" ~
					"coalfile.private file inside the build directory.\n\n" ~
					"Example:\n" ~
					CTRACE ~ "\tcoal add --name \"lib\" --path \"D:/libs/some_lib/\" --include \"Include/\"\n" ~ CCLEAR ~
					"\tThis will add a library " ~ CFOCUS ~ "lib" ~ CCLEAR ~ "\n" ~
					"\tlocated in " ~ CFOCUS ~ "D:/libs/some_lib/" ~ CCLEAR ~ "\n" ~
					"\tand all the header files in its " ~ CFOCUS ~ "Include" ~ CCLEAR ~ "\n" ~
					"\tsubdirectory will be added to the project."
				)
				.set_callback(&do_add)
		)
		.subcommand(
			new Command("build", "Build project")
				.arg(Arg.single("release", "r", "Release type", "none", ALLOWED_BUILD_MODES))
				.set_longer_desc(
					"This command generates a brand new CMakeLists.txt,\n" ~
					"configures the CMake project and builds the program.\n" ~
					"Any new .cpp files or changes to coalfile will take\n" ~
					"effect during the build.\n" ~
					"You can specify the release mode (debug, release etc.)\n" ~
					"using the " ~ CFOCUS ~ "release" ~ CCLEAR ~ " argument. The flags for each build\n" ~
					"mode are configured in the coalfile."
				)
				.set_callback(&do_build)
		)
		.subcommand(
			new Command("run", "Build and run project")
				.arg(Arg.flag("no-build", null, "Don't build project", false))
				.arg(Arg.single("release", "r", "Release type", "none", ALLOWED_BUILD_MODES))
				.set_longer_desc(
					"This command builds and runs the project. The build\n" ~
					"process is identical to " ~ CFOCUS ~ "coal build" ~ CCLEAR ~ " and it can be\n" ~
					"skipped by specifying the " ~ CFOCUS ~ "no-build" ~ CCLEAR ~ " argument."
				)
				.set_callback(&do_run)
		)
		.subcommand(
			new Command("template", "Manage project templates")
				.subcommand(
					new Command("ls", "List all templates")
					.arg(Arg.flag("verbose", "v", "Show verbose output", false))
					.set_callback(&do_list_template)
				)
				.subcommand(
					new Command("new", "Add new template")
					.arg(Arg.single("name", "n", "Template name", null))
					.arg(Arg.single("desc", "d", "Template description", null))
					.arg(Arg.single("path", "p", "Full path to template's root folder", null))
					.set_longer_desc(
					"This command adds a new project template.\n" ~
					"A template is a directory on your computer\n" ~
					"which can be used as a starting point for\n" ~
					"new projects. A template does not have to\n" ~
					"have a coalfile.\n\n" ~
					"When a template is cloned, all of its files\n" ~
					"(except for maintenance files like .git/)\n" ~
					"are copied to the specified destination.\n\n" ~
					"Template definitions are stored in a JSON\n" ~
					"file located in the coal executable path.\n\n" ~
					"Templates are identified by their names,\n" ~
					"so the template name must be unique.\n\n" ~
					"Example:\n" ~
					CTRACE ~ "\tcoal template new --name \"win32\" --path \"D:/user/programs/win32_base/\" --desc \"Base project for Win32\"\n" ~ CCLEAR ~
					"\tThis delcares a template " ~ CFOCUS ~ "win32" ~ CCLEAR ~ "\n" ~
					"\twhose files are located in\n\t" ~ CFOCUS ~ "D:/user/programs/win32_base/" ~ CCLEAR ~ ".\n" ~
					"\tYou can clone this template\n\tusing " ~ CTRACE ~ "coal template clone" ~ CCLEAR ~ ".")
					.set_callback(&do_new_template)
				)
				.subcommand(
					new Command("clone", "Clone project from template")
					.arg(Arg.single("template", "t", "Template name", null))
					.arg(Arg.single("name", "n", "Project name", null))
					.arg(Arg.single("src", "s", "Source code directory (relative)", null))
					.arg(Arg.single("build", "b", "Binaries directory (relative)", null))
					.arg(Arg.single("generator", "g", "Which CMake generator to use", null))
					.set_longer_desc(
					"This command copies files of a template to\n" ~
					"another location on your computer. Compared\n" ~
					"to " ~ CTRACE ~ "coal init" ~ CCLEAR ~ ", this command doesn't generate\n" ~
					"a stub project or a new coalfile unless the\n" ~
					"template doesn't have a coalfile already.\n\n" ~
					"If a coalfile doesn't exist, you must pass\n" ~
					"certain project argument like the build dir\n" ~
					"and generator type. Otherwise, the project\n" ~
					"name is the only argument you must always\n" ~
					"specify (the cloned project should not have\n" ~
					"the same name like the template).\n\n" ~
					"Example:\n" ~
					CTRACE ~ "\tcoal template clone --template \"win32\" --name \"calculator\"\n" ~ CCLEAR ~
					"\tThis clones a template " ~ CFOCUS ~ "win32" ~ CCLEAR ~ "\n" ~
					"\tto the current shell path\n" ~
					"\tand creates a project called\n\t" ~ CFOCUS ~ "calculator" ~ CCLEAR ~ "."
					)
					.set_callback(&do_new_template)
					.set_callback(&do_clone_from_template)
				)
		)
		.subcommand(new Command("clean", "Clean build files and CMake cache")
				.arg(Arg.flag("program", "p", "Also remove program binaries and DLLs", false))
				.set_callback(&do_clean)
				.set_longer_desc(
					"This command deletes all build files and any\n" ~
					"cached CMake/Make/Ninja/etc. data along with\n" ~
					"it. The program binary and .dll files from\n" ~
					"the program's dependencies are not removed\n" ~
					"unless you pass the " ~ CFOCUS ~ "program" ~ CCLEAR ~ " flag.")
		);
	handle(root, args, "coal");
}
