import coalfile;
import project;
import std.path;
import std.string;
import std.stdio;
import std.file;
import std.array;
import std.conv;
import std.process;
import clyd.color;
import clyd.command;
import core.stdc.stdlib;
import std.algorithm;
import config;
import std.datetime.stopwatch;

private void print_time(string project_name, ref StopWatch sw_full, ref StopWatch sw_cmake)
{
	string get_time_string(ref StopWatch stopwatch)
	{
		string build_time = to!(string)(stopwatch.peek());

		// We don't need sub-ms precision.

		long i = build_time.indexOf("ms");
		if (i >= 0)
		{
			build_time = build_time[0 .. (i + "ms".length)];
		}

		return build_time;
	}

	writeln(CTRACE ~ "    [    coal build] "
			~ CINFO ~ "Finished building "
			~ CFOCUS ~ project_name
			~ CINFO ~ " in "
			~ CTRACE ~ get_time_string(
				sw_full) ~ "\n"
			~ CINFO ~ "                     CMake build took "
			~ CTRACE ~ get_time_string(sw_cmake)
			~ CCLEAR);
	write(CCLEAR);
}

void do_build(Command cmd)
{
	Project p = load();

	auto sw = StopWatch(AutoStart.no);
	auto sw_cmake = StopWatch(AutoStart.no);

	sw.start();

	writeln(CTRACE ~ "    [1/3 coal build] " ~ CINFO ~ "Generating CMakeLists.txt for " ~ CFOCUS ~ p.name ~ CINFO);
	create_cmakelists(p);

	writeln(
		CTRACE ~ "    [2/3 coal build] " ~ CINFO ~ "Configuring CMake project " ~ CFOCUS ~ p.name ~ CINFO);
	configure_cmakelists(p, cmd.args["release"].value);

	sw_cmake.start();

	writeln(CTRACE ~ "    [3/3 coal build] " ~ CINFO ~ "Building " ~ CFOCUS ~ p.name ~ CINFO);
	build_project(p);

	sw_cmake.stop();
	sw.stop();

	print_time(p.name, sw, sw_cmake);
}

void do_run(Command cmd)
{
	if (!cmd.args["no-build"].is_set_flag)
	{
		// DANGEROUS: do_build expects a build-cmd, not a run-cmd.
		do_build(cmd);
	}

	do_just_run(cmd.get_application_arguments());
}

void do_just_run(string[] args)
{
	Project p = load();

	writeln(CTRACE ~ "    [1/1 coal run] " ~ CINFO ~ "Running executable " ~ CFOCUS ~ p.name ~ CCLEAR);

	const string program_path = buildPath(".", p.build_dir, p.name) ~ ".exe";
	const string[] params = args;

	auto proc = spawnProcess([program_path] ~ params);
	int code = wait(proc);
	if (code != 0)
	{
		writefln(CERR ~ "    [ERR coal run] %s exited with code %d" ~ CCLEAR, p.name, code);
		exit(1);
	}
}

void build_project(Project p)
{
	auto proc = spawnProcess(["cmake", "--build", buildPath(".", p.build_dir)]);
	int code = wait(proc);
	if (code != 0)
	{
		writefln(CERR ~ "    [ERR coal build] CMake build exited with code %d" ~ CCLEAR, code);
		exit(1);
	}
}

void configure_cmakelists(Project p, string build_mode)
{
	string[] vars = [];

	CoalFilePrivate coalfile_private;
	coalfile_private.load(p.get_coalfile_private_fname());
	foreach (key, val; coalfile_private.lib_paths)
	{
		vars ~= format("-D%s=%s", key, val);
	}

	auto proc = spawnProcess([
		"cmake",
		"-S", ".",
		"-B", buildPath(".", p.build_dir),
		"-G", p.generator,
		"-DCMAKE_BUILD_TYPE=" ~ get_build_mode_cmake_param(build_mode)
	] ~ vars);
	int code = wait(proc);
	if (code != 0)
	{
		writefln(CERR ~ "    [ERR coal build] CMake configure exited with code %d" ~ CCLEAR, code);
		exit(1);
	}
}

void create_cmakelists(Project p)
{
	CMakeLists_Manifest m = build_cmakelists_manifest(p);
	string s = generate_cmakelists_text(m, p);
	string path = buildPath(".", "CMakeLists.txt");

	File file = File(path, "w");
	file.write(s);
	file.close();
}

struct CMakeLists_Manifest
{
	string[] source_files = [];
	string[] include_dirs = [];
	string[2][] set_path_vars = [];
	string[] link_dirs = [];
	string[] link_libs = [];
	string[] copy_dlls = [];
}

CMakeLists_Manifest build_cmakelists_manifest(Project p)
{
	const string source_file_ext = ".cpp";

	CMakeLists_Manifest result;

	foreach (dir; p.source_dirs)
	{
		result.include_dirs ~= dir;

		string dir_rel = buildPath(".", dir);

		if (!exists(dir_rel))
		{
			writeln(CERR ~ "Could not find source dir " ~ CFOCUS ~ dir ~ CCLEAR);
			exit(1);
		}

		foreach (entry; dirEntries(dir_rel, SpanMode.depth))
		{
			if (entry.isFile && entry.name.extension == source_file_ext)
			{
				result.source_files ~= entry.name;
			}
		}
	}

	foreach (lib; p.libs)
	{
		const string lib_var = lib.get_dir_var();
		result.set_path_vars ~= [lib.get_dir_var_name(), lib_var];

		foreach (include_dir; lib.include_dirs)
		{
			result.include_dirs ~= buildPath(lib_var, include_dir);
		}

		foreach (link_dir; lib.lib_dirs)
		{
			result.link_dirs ~= buildPath(lib_var, link_dir);
		}

		foreach (link_lib; lib.link_libs)
		{
			result.link_libs ~= link_lib;
		}

		foreach (dll_file; lib.dll_dirs)
		{
			result.copy_dlls ~= buildPath(lib_var, dll_file);
		}

		foreach (src_file; lib.get_source_files())
		{
			result.source_files ~= buildPath(lib.get_dir_var(), src_file);
		}
	}

	return result;
}

string generate_cmakelists_text(const ref CMakeLists_Manifest manifest, Project p)
{
	auto S = appender!string();

	S.put("############################################################\n");
	S.put("# This CMakeLists.txt was generated by coal.\n");
	S.put("# Do not modify the contents of this file, because coal will\n");
	S.put("# overwrite changes on the next build. Any modifications\n");
	S.put("# should be handled through the project's coalfile, which is\n");
	S.put("# located at the root of the project.\n");
	S.put("############################################################\n");
	S.put("\n");

	S.put(format("cmake_minimum_required(VERSION %s...%s)\n",
			p.cmake_version_min, p.cmake_version_max));
	S.put("\n");
	S.put(format("project(%s VERSION 1.0 LANGUAGES CXX)\n", p.name));
	S.put(format("set(CMAKE_CXX_STANDARD %s)\n", p.cpp_version));
	S.put(format("set(CMAKE_EXPORT_COMPILE_COMMANDS 1)\n"));
	S.put("\n");

	if (manifest.set_path_vars.length > 0)
	{
		foreach (path_var; manifest.set_path_vars)
		{
			S.put(format("set(%s %s CACHE PATH \"Path to %s\")\n", path_var[0], path_var[1], path_var[0]));
		}
		S.put("\n");
	}

	if (manifest.include_dirs.length > 0)
	{
		S.put("include_directories(\n");
		foreach (include_dir; manifest.include_dirs)
		{
			S.put(format("    %s\n", include_dir.replace("\\", "/")));
		}
		S.put(")\n");
		S.put("\n");
	}

	if (manifest.link_dirs.length > 0)
	{
		S.put("link_directories(\n");
		foreach (link_dir; manifest.link_dirs)
		{
			S.put(format("    %s\n", link_dir.replace("\\", "/")));
		}
		S.put(")\n");
		S.put("\n");
	}

	if (manifest.source_files.length > 0)
	{
		S.put("set(SOURCES\n");
		foreach (source_file; manifest.source_files)
		{
			S.put(format("    %s\n", source_file.replace("\\", "/")));
		}
		S.put(")\n");
		S.put("\n");
	}

	S.put(format("add_executable(%s ${SOURCES})\n", p.name));
	S.put("\n");

	// Compiler flags

	if (p.flags.length > 0)
	{
		string compiler_flags = p.flags.map!(preprocess_compiler_flag).join(";");

		S.put(format("target_compile_options(%s PRIVATE\n", p.name));
		S.put(format("\t$<$<COMPILE_LANGUAGE:CXX>:%s>\n", compiler_flags));
		S.put(format(")\n"));
		S.put("\n");
	}

	// Link flags

	if (p.link_flags.length > 0)
	{
		string link_flags = p.link_flags.map!(preprocess_link_flag).join(";");

		S.put(format("target_link_options(%s PRIVATE\n", p.name));
		S.put(format("\t%s\n", link_flags));
		S.put(format(")\n"));
		S.put("\n");
	}

	// Build-specific compiler flags
	{
		S.put(format("target_compile_options(%s PRIVATE\n", p.name));
		foreach (build_mode_flag; ALLOWED_BUILD_MODES)
		{
			string build_mode_name = get_build_mode_cmake_param(build_mode_flag);
			string build_mode_definition_macro_name = build_mode_flag
				.replace("-", "_")
				.replace(" ", "_")
				.toUpper();
			string[] build_mode_flags = p.build_specific_flags[build_mode_flag];

			build_mode_flags ~= "D" ~ build_mode_definition_macro_name;
			S.put(format("\t$<$<CONFIG:%s>:%s>\n",
					build_mode_name,
					build_mode_flags.map!(preprocess_compiler_flag).join(";")
			));
		}
		S.put(format(")\n"));
		S.put("\n");
	}

	if (manifest.link_libs.length > 0)
	{
		S.put(format("target_link_libraries(%s\n", p.name));
		foreach (link_lib; manifest.link_libs)
		{
			S.put(format("    %s\n", link_lib));
		}
		S.put(")\n");
		S.put("\n");
	}

	if (manifest.copy_dlls.length > 0)
	{
		S.put(format("if (WIN32)\n"));
		S.put(format(
				"    add_custom_command(TARGET %s POST_BUILD\n", p.name));
		foreach (dll; manifest.copy_dlls)
		{
			S.put(format(
					"        COMMAND ${CMAKE_COMMAND} -E copy_if_different %s $<TARGET_FILE_DIR:%s>\n",
					dll.replace("\\", "/"),
					p.name)
			);
		}
		S.put(format("    )\n"));
		S.put(format("endif()\n"));
	}

	return S.data.strip;
}

private string get_build_mode_cmake_param(string build_mode)
{
	switch (build_mode)
	{
	case "none":
		return "None";
	case "debug":
		return "Debug";
	case "release":
		return "Release";
	case "minsize":
		return "RelMinSize";
	case "releasedebug":
		return "RelDebug";
	default:
		{
			string fallback = "None";
			writeln(
				CWARN ~ "Unknown build mode " ~ CFOCUS ~ build_mode);
			writeln(
				CINFO ~ "Defaulting to fallback " ~ CFOCUS ~ fallback ~ CCLEAR);
			return fallback;
		}
	}
}

private string preprocess_compiler_flag(string flag)
{
	if (flag.startsWith("-"))
		return flag;
	return "-" ~ flag;
}

private string preprocess_link_flag(string flag)
{
	if (flag.startsWith("-"))
		return flag;
	return "-" ~ flag;
}
