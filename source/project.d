import std.json;
import std.algorithm;
import std.array;
import std.stdio;
import std.path;
import std.file;
import coalfile;
import config;
import clyd.color;
import json;

class Project
{
	string name = "";
	string[] source_dirs = [];
	string build_dir = "";
	string generator = "";
	Library[] libs = [];
	string cmake_version_min = "";
	string cmake_version_max = "";
	string cpp_version = "";
	string[][string] build_specific_flags = DEFAULT_COMPILER_FLAGS_DEFAULT;
	string[] flags = [];
	string[] link_flags = [];

	Project clone() const
	{
		Project p = new Project();
		p.from_json_coalfile(to_json_coalfile());
		return p;
	}

	JSONValue to_json_coalfile() const
	{
		JSONValue j;
		j["name"] = name;
		j["source_dirs"] = source_dirs;
		j["build_dir"] = build_dir;
		j["generator"] = generator;
		j["cmake_version_min"] = cmake_version_min;
		j["cmake_version_max"] = cmake_version_max;
		j["cpp_version"] = cpp_version;
		j["flags"] = flags;
		j["link_flags"] = link_flags;

		JSONValue[] libs_json = [];
		foreach (const Library lib; libs)
		{
			libs_json ~= lib.to_json_coalfile();
		}
		j["libs"] = libs_json;

		JSONValue build_specific_flags_json;
		foreach (k, v; build_specific_flags)
		{
			build_specific_flags_json[k] = v;
		}
		j["build_specific_flags"] = build_specific_flags_json;

		return j;
	}

	void from_json_coalfile(JSONValue j)
	{
		name = j["name"].str;
		source_dirs = j["source_dirs"].array.map!(x => x.str).array;
		build_dir = j["build_dir"].str;
		generator = j["generator"].str;

		cmake_version_min = j.get_string("cmake_version_min", "3.15");
		cmake_version_max = j.get_string("cmake_version_max", "4.0");
		cpp_version = j.get_string("cpp_version", "14");
		flags = j.get_strings("flags", []);
		link_flags = j.get_strings("link_flags", []);

		foreach (const lib_json; j.get_arr("libs"))
		{
			Library lib;
			lib.from_json_coalfile(lib_json);
			libs ~= lib;
		}

		foreach (k, v; j.get_obj("build_specific_flags"))
		{
			build_specific_flags[k] = v.array.map!(x => x.str).array;
		}
	}

	JSONValue to_json_coalfile_private() const
	{
		JSONValue j;

		string[string] lib_paths;
		foreach (const Library lib; libs)
		{
			lib_paths[lib.get_dir_var_name()] = lib.path;
		}
		j["lib_paths"] = lib_paths;

		return j;
	}

	void from_json_coalfile_private(CoalFilePrivate p)
	{
		foreach (lib_name, lib_path; p.lib_paths)
		{
			for (int i = 0; i < libs.length; i++)
			{
				if (libs[i].get_dir_var_name() == lib_name)
				{
					libs[i].path = lib_path;
					break;
				}
			}
		}
	}

	string get_coalfile_private_fname(string directory = ".") const
	{
		return buildPath(directory, build_dir, "coalfile.private");
	}

	string get_coalfile_fname(string directory = ".") const
	{
		return buildPath(directory, "coalfile");
	}

}

struct Library
{
	string name = "";
	string[] include_dirs = [];
	string[] lib_dirs = [];
	string[] dll_dirs = [];
	string[] link_libs = [];
	string[] sources = [];

	// Absolute path to the library directory. This is kept in the private
	// coalfile and is loaded by the Project. The default value is `null`. That
	// way, once the Project is loaded, we can check if any of its libraries
	// have a `null` path, and if so, that means that the private coalfile is
	// invalid or corrupted, and we prompt the user to re-enter the path to the
	// libraries that have a null path (if any).
	string path = null;

	JSONValue to_json_coalfile() const
	{
		JSONValue j;
		j["name"] = name;
		j["include_dirs"] = include_dirs;
		j["lib_dirs"] = lib_dirs;
		j["dll_dirs"] = dll_dirs;
		j["link_libs"] = link_libs;
		j["sources"] = sources;
		return j;
	}

	void from_json_coalfile(JSONValue j)
	{
		name = j["name"].str;

		include_dirs = j.get_strings("include_dirs", []);
		lib_dirs = j.get_strings("lib_dirs", []);
		dll_dirs = j.get_strings("dll_dirs", []);
		link_libs = j.get_strings("link_libs", []);
		sources = j.get_strings("sources", []);

		path = null;
	}

	string get_dir_var_name() const
	{
		return name ~ "_LIBDIR";
	}

	string get_dir_var() const
	{
		return "${" ~ get_dir_var_name() ~ "}";
	}

	string[] get_source_files() const
	{
		string[] res = [];

		foreach (src; sources)
		{
			string src_full_path = buildPath(path, src);

			if (!exists(src_full_path))
			{
				writeln(CWARN ~ "Unknown " ~ CFOCUS ~ src ~ CWARN ~ " in library " ~ CFOCUS ~ name ~ CCLEAR);
				continue;
			}

			string[] src_expanded = [];

			if (isDir(src_full_path))
			{
				alias dir = src_full_path;
				const string source_file_ext = ".cpp";

				foreach (entry; dirEntries(dir, SpanMode.depth))
				{
					if (entry.isFile && entry.name.extension == source_file_ext)
					{
						string entry_relative = relativePath(entry.name, path);
						src_expanded ~= entry_relative;
					}
				}
			}
			else
			{
				src_expanded ~= src;
			}

			res ~= src_expanded;
		}

		return res;
	}
}
