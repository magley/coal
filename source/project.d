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
	string cmake_version_min = "3.15";
	string cmake_version_max = "4.0";
	string cpp_version = "14";
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
		mixin(get_json_field!("name", "str", false));
		mixin(get_json_field!("source_dirs", "strarr", false));
		mixin(get_json_field!("build_dir", "str", false));
		mixin(get_json_field!("generator", "str", false));

		mixin(get_json_field!("cmake_version_min", "str", true));
		mixin(get_json_field!("cmake_version_max", "str", true));
		mixin(get_json_field!("cpp_version", "str", true));
		mixin(get_json_field!("flags", "strarr", true));
		mixin(get_json_field!("link_flags", "strarr", true));

		foreach (const lib_json; j.safe("libs").arr_or([]))
		{
			Library lib;
			lib.from_json_coalfile(lib_json);
			libs ~= lib;
		}

		foreach (k, v; j.safe("build_specific_flags").obj_or(null))
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
		mixin(get_json_field!("name", "str", false));
		mixin(get_json_field!("include_dirs", "strarr", true));
		mixin(get_json_field!("lib_dirs", "strarr", true));
		mixin(get_json_field!("dll_dirs", "strarr", true));
		mixin(get_json_field!("link_libs", "strarr", true));
		mixin(get_json_field!("sources", "strarr", true));

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
				writeln(
					CWARN ~ "Unknown " ~ CFOCUS ~ src ~ CWARN ~ " in library " ~ CFOCUS ~ name ~ CCLEAR);
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

/// Simplify safely getting a value from `j`. Used in mixins, to reduce
/// the number of times a same identifier is specified.
///
/// Params:
/// - **name** The name of the field, its json value must be the same.
/// - **conv_func** JsonSafe conversion method stem, for example `str`
///   or `strarr` (Without the `_or`).
/// - **offer_default** When `false`, if the value is missing from json
///   that counts as an error. When `true`, if the value is missing from
///   json then it will use the default value for the `name` field.
///   which is defined by the underlying class (so, it's not the default
///   for _all_ strings).
///
/// Returns: A mixin declaration, like: `name = j.safe("name").str;` or
/// `name = j.safe("name").str_orr(name);`
private string get_json_field(string name, string conv_func, bool offer_default)()
{
	string s = name ~ " = j.safe(\"" ~ name ~ "\")." ~ conv_func;

	if (offer_default)
	{
		s ~= "_or(" ~ name ~ ")";
	}
	s ~= ";";

	return s;
}
