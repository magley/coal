import core.stdc.stdlib;
import project;
import std.file;
import std.json;
import std.path;
import std.stdio;
import std.algorithm;
import std.format;
import input;

void save(Project p)
{
	// Bulid coalfile
	{
		string fname = buildPath(".", "coalfile");

		JSONValue j = p.to_json_coalfile();
		File file = File(fname, "w");
		file.write(j.toPrettyString(JSONOptions.doNotEscapeSlashes));
		file.close();
	}

	// Create build directory
	{
		string dir = buildPath(".", p.build_dir);
		if (!exists(dir))
		{
			mkdir(dir);
		}
	}

	// Build coalfile.private
	{
		string fname = buildPath(".", p.build_dir, "coalfile.private");

		JSONValue j = p.to_json_coalfile_private();
		File file = File(fname, "w");
		file.write(j.toPrettyString(JSONOptions.doNotEscapeSlashes));
		file.close();
	}
}

Project load()
{
	ensure_coalfile_exists();
	Project p = new Project();

	// Load coalfile.
	{
		string fname = p.get_coalfile_fname();
		string json_string = readText(fname);
		JSONValue j = parseJSON(json_string);
		p.from_json_coalfile(j);
	}

	// Load coalfile.private.
	{
		string fname = p.get_coalfile_private_fname();
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
				writeln(format("[%s] %s: '%s'", lib.name, path_error, lib.path));
				string new_path = input_dir_non_empty(format("Enter path for library %s", lib.name));
				lib.path = new_path;
			}
		}
	}

	save(p);
	return p;
}

private void ensure_coalfile_exists()
{
	string fname = buildPath(".", "coalfile");
	if (exists(fname))
	{
		return;
	}
	writeln("No coalfile found! Initialize a coalfile project with `coalfile init`\n");
	exit(1);
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
