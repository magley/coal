import std.file;
import std.path;
import std.stdio;
import std.algorithm;
import std.uni;
import std.container.rbtree;
import std.array;

/// Copy contents of folder `source` into folder `destination`. 
void copy_folder_contents(
    string source,
    string destination,
    string[] _ignore_folders = [],
    string[] _ignore_files = [],
    bool case_insensitive = false)
{
    auto ignore_folders = redBlackTree!string();
    foreach (string name; _ignore_folders)
    {
        string n = case_insensitive ? name : name.toLower();
        ignore_folders.insert(n);
    }
    auto ignore_files = redBlackTree!string();
    foreach (string name; _ignore_files)
    {
        string n = case_insensitive ? name : name.toLower();
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

bool is_subdirectory(string haystack, string needle, bool case_insensitive = false)
{
    string absA = haystack.buildPath.absolutePath.replace("\\", "/");
    string absB = needle.buildPath.absolutePath.replace("\\", "/");

    if (case_insensitive)
    {
        absA = absA.toLower();
        absB = absB.toLower();
    }

    string rel = relativePath(absB, absA);

    if (rel.startsWith(".."))
        return false;
    if (rel == absB)
        return false;
    return true;
}

unittest
{
    assert(!is_subdirectory("./src", "."));
    assert(!is_subdirectory("./src", "./bin"));
    assert(is_subdirectory("./src", "./src"));
    assert(is_subdirectory("./src", "./src/bi"));
    assert(!is_subdirectory("./src", "./src2"));
    assert(!is_subdirectory("C:/gogo", "D:/gogo"));
    assert(!is_subdirectory("a/b", "b/a"));

}
