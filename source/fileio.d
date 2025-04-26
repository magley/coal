import std.file;
import std.path;
import std.stdio;
import std.algorithm;
import std.uni;
import std.container.rbtree;

/// Copy contents of folder `source` into folder `destination`. 
void copy_folder_contents(
    string source,
    string destination,
    string[] _ignore_folders = [],
    string[] _ignore_files = [],
    bool ignore_name_case_sensitive = false)
{
    auto ignore_folders = redBlackTree!string();
    foreach (string name; _ignore_folders)
    {
        string n = ignore_name_case_sensitive ? name : name.toLower();
        ignore_folders.insert(n);
    }
    auto ignore_files = redBlackTree!string();
    foreach (string name; _ignore_files)
    {
        string n = ignore_name_case_sensitive ? name : name.toLower();
        ignore_files.insert(n);
    }

    mkdirRecurse(destination);

    foreach (const ref entry; dirEntries(source, SpanMode.shallow))
    {
        const string name = baseName(entry.name);
        if (entry.isDir)
        {
            if (name in ignore_folders)
                continue;
        }
        else
        {
            if (name in ignore_files)
                continue;

        }

        const string destPath = buildPath(destination, name);

        if (entry.isDir)
        {
            copy_folder_contents(entry.name, destPath);
        }
        else
        {
            copy(entry.name, destPath);
        }
    }
}
