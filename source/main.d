import clyd.command;
import clyd.handler;
import clyd.arg;

import init;
import add;
import build;
import templates;
import clean;
import config;

const VERSION = "0.4";

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

				.set_callback((Command cmd) { do_init_new(cmd); })
		)
		.subcommand(
			new Command("add", "Add local library as dependency to project")
				.arg(Arg.single("name", "n", "Name of library", null))
				.arg(Arg.single("path", "p", "Full path to root of library", null))
				.arg(Arg.multiple("include", "i", "Include directories", []))
				.arg(Arg.multiple("lib", "l", "Library directories", []))
				.arg(Arg.multiple("link", "L", "Link directives", []))
				.arg(Arg.multiple("dll", null, "DLL files to copy", []))
				.set_callback(&do_add)
		)
		.subcommand(
			new Command("build", "Build project")
				.set_callback(&do_build)
		)
		.subcommand(
			new Command("run", "Build and run project")
				.arg(Arg.flag("no-build", null, "Don't build project", false))
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
					.set_callback(&do_new_template)
				)
				.subcommand(
					new Command("clone", "Clone project from template")
					.arg(Arg.single("template", "t", "Template name", null))
					.arg(Arg.single("name", "n", "Project name", null))
					.arg(Arg.single("src", "s", "Source code directory (relative)", null))
					.arg(Arg.single("build", "b", "Binaries directory (relative)", null))
					.arg(Arg.single("generator", "g", "Which CMake generator to use", null))
					.set_callback(&do_clone_from_template)
				)
		)
		.subcommand(new Command("clean", "Clean build files and CMake cache")
				.arg(Arg.flag("program", "p", "Also remove program binaries and DLLs", false))
				.set_callback(&do_clean)
		);

	handle(root, args, "coal");
}
