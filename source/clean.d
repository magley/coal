import clyd.command;
import project;
import coalfile;
import std.file;
import std.path;

void do_clean(Command cmd)
{
    Project p = load();
    string b = p.build_dir;

    delfile(b, "CMakeFiles/");
    delfile(b, "cmake_install.cmake");
    delfile(b, "CMakeCache.txt");
    delfile(b, "compile_commands.json");
    delfile(b, "Makefile");

    if (cmd.args["program"].is_set_flag)
    {
        delfile(b, p.name);
        delfile(b, p.name ~ ".exe");

        foreach (lib; p.libs)
        {
            foreach (dll; lib.dll_dirs)
            {
                delfile(b, baseName(dll));
            }
        }
    }
}

private void delfile(string build_dir, string fname)
{
    string path = buildPath(build_dir, fname);
    if (exists(path))
    {
        if (isDir(path))
        {
            rmdirRecurse(path);
        }
        else
        {
            remove(path);
        }
    }
}
