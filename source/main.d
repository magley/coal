import clyd.command;
import clyd.handler;
import clyd.arg;

import init;
import add;
import build;
import templates;

const VERSION = "0.3";

void main(string[] args)
{
	Command root = new Command("coal", "Coal version " ~ VERSION)
		.subcommand(
			new Command("init", "Initialize a new project")
				.arg(Arg.single("name", "n", "Project name", null))
				.arg(Arg.single("src", "s", "Source code directory (relative)", "src/"))
				.arg(Arg.single("build", "b", "Binaries directory (relative)", "build/"))
				.arg(Arg.single("generator", "g", "Which CMake generator to use", "MinGW Makefiles"))
				.set_callback((Command cmd) { do_init(cmd); })
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
		);

	handle(root, args);
}
