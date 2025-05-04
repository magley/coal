import core.stdc.stdlib;
import project;
import std.file;
import std.json;
import std.path;
import std.stdio;
import std.algorithm;
import std.format;
import input;

void save(Project p, string directory = ".")
{
	// Bulid coalfile
	{
		string fname = buildPath(directory, "coalfile");

		JSONValue j = p.to_json_coalfile();
		File file = File(fname, "w");
		file.write(j.toPrettyString(JSONOptions.doNotEscapeSlashes));
		file.close();
	}

	// Create build directory
	{
		string dir = buildPath(directory, p.build_dir);
		if (!exists(dir))
		{
			mkdir(dir);
		}
	}

	// Build coalfile.private
	{
		string fname = buildPath(directory, p.build_dir, "coalfile.private");

		JSONValue j = p.to_json_coalfile_private();
		File file = File(fname, "w");
		file.write(j.toPrettyString(JSONOptions.doNotEscapeSlashes));
		file.close();
	}
}

Project load(string directory = ".")
{
	ensure_coalfile_exists(directory);
	Project p = new Project();

	// Load coalfile.
	{
		string fname = p.get_coalfile_fname(directory);
		string json_string = readText(fname);
		JSONValue j = parseJSON(json_string);
		p.from_json_coalfile(j);
	}

	// Load coalfile.private.
	{
		string fname = p.get_coalfile_private_fname(directory);
		CoalFilePrivate coalfile_private;

		if (exists(fname))
		{
			coalfile_private.load(fname);
			p.from_json_coalfile_private(coalfile_private);
		}
	}

	// Handle invalid library paths.
	{
		foreach (ref lib; p.libs)
		{
			string path_error = null;
			if (lib.path == null)
			{
				path_error = "Path not specified";
			}
			else if (!exists(lib.path))
			{
				path_error = "Path does not exist";
			}
			else if (!isDir(lib.path))
			{
				path_error = "Path is not a directory";
			}

			if (path_error != null)
			{
				writefln(CFOCUS ~ "[%s] " ~ CINFO ~ "%s: " ~ CERR ~ "'%s'" ~ CCLEAR, lib.name, path_error, lib
						.path);
				string new_path = input_dir_non_empty(format("Enter path for library %s", lib.name));
				lib.path = new_path;
			}
		}
	}

	return p;
}

private void ensure_coalfile_exists(string directory = ".")
{
	if (!coalfile_exists(directory))
	{
		writeln(
			CERR ~ "No coalfile found!\n" ~ CCLEAR ~ "Initialize a coalfile project with " ~ CFOCUS ~ "coal init" ~ CCLEAR);
		exit(1);
	}
}

void ensure_coalfile_not_exists(string directory = ".")
{
	if (coalfile_exists(directory))
	{
		writefln(CERR ~ "Target directory already contains a coalfile" ~ CCLEAR);
		exit(1);
	}
}

bool coalfile_exists(string directory = ".")
{
	string fname = buildPath(directory, "coalfile");
	return exists(fname);
}

struct CoalFilePrivate
{
	string[string] lib_paths;

	void load(string fname)
	{
		string json_string = readText(fname);
		JSONValue j = parseJSON(json_string);

		foreach (key, val; j["lib_paths"].object)
		{
			lib_paths[key] = val.str;
		}
	}
}
