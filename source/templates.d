import cli;
import std.file;
import std.json;
import std.algorithm;
import std.array;
import std.path;
import std.stdio;
import core.stdc.stdlib;
import coalfile;
import std.typecons;
import std.conv;

void do_new_template(const ref Command_template_new cmd)
{
    Template t = new Template();
    t.name = cmd.name.get;
    t.path = cmd.path.get;
    t.description = cmd.desc.get;

    if (!exists(t.path))
    {
        writefln("Path %s doesn't exist", t.path);
        exit(1);
    }
    t.path = absolutePath(t.path).dirName().replace("\\", "/");
    if (!isDir(t.path))
    {
        writefln("Path %s is not a directory", t.path);
        exit(1);
    }

    TemplatesFile templates = load_templates();
    if (templates.templates.any!(o => o.name == t.name))
    {
        writefln("A template called %s already exists", t.name);
        exit(1);
    }

    templates.templates ~= t;
    save_templates(templates);
}

void do_spawn_from_template(const ref Command_template_spawn cmd)
{
    import project;

    const TemplatesFile templates = load_templates();

    // [1] Load template.

    const Template t = templates.get_template(cmd.template_name.get);
    if (t is null)
    {
        writefln("Unknown template %s", cmd.template_name.get);
        exit(1);
    }

    // [2] Create project file.
    //
    // We *could* copy all files and then construct a project, but if this
    // function fails, you're left with a bunch of files and an invalid project.
    // One case where the function fails is if a coalfile is missing and you
    // didn't specify some parameter properly. It's not a good idea to copy
    // first, do logic, and then delete files in case of an error.

    Project p;
    if (coalfile_exists(t.path))
    {
        Project template_project = load(t.path);
        p = template_project.clone();
        p.name = cmd.project_name.get();
        save(p, ".");
    }
    else
    {
        import init;

        writefln("No coalfile at %s", t.path);
        writeln("A coalfile will be created for the new project");
        writeln("Make sure to specify all the parameters like when initializing a blank project");
        writeln();

        p = do_init(cmd);
    }
    assert(exists("./coalfile"));

    // [3] Copy files.

    {
        import fileio;

        // We ignore `coalfile` here because we have already created one from a
        // Project. If we were to copy the coalfile here, it would override any
        // changes (for example: project name).
        copy_folder_contents(t.path, ".", [".git", p.build_dir], ["coalfile"]);

        // Copy coalfile.private from template (because we ignore build dir
        // which is where coalfile.private is kept).
        {
            string src = buildPath(t.path, p.build_dir, "coalfile.private");
            if (exists(src))
            {
                string dst = buildPath(p.build_dir, "coalfile.private");
                copy(src, dst);
            }
        }
    }
}

class Template
{
    string name;
    string path;
    string description;

    JSONValue to_json() const
    {
        JSONValue j;
        j["name"] = name;
        j["path"] = path;
        j["description"] = description;
        return j;
    }

    void from_json(const ref JSONValue j)
    {
        name = j["name"].str;
        path = j["path"].str;
        description = j["description"].str;
    }
}

class TemplatesFile
{
    Template[] templates;

    JSONValue to_json() const
    {
        JSONValue j;

        j["templates"] = templates.map!(t => t.to_json()).array();

        return j;
    }

    void from_json(const ref JSONValue j)
    {
        Template template_from_json(const ref JSONValue j)
        {
            Template t = new Template();
            t.from_json(j);
            return t;
        }

        templates = j["templates"].array().map!(t => template_from_json(t)).array();
    }

    const(Template) get_template(string name) const
    {
        foreach (const Template t; templates)
        {
            if (t.name == name)
            {
                return t;
            }
        }
        return null;
    }
}

private string get_templates_file_path()
{
    return buildPath(thisExePath().dirName(), "templates.json");
}

private TemplatesFile load_templates()
{
    TemplatesFile t = new TemplatesFile();
    const string path = get_templates_file_path();

    if (exists(path))
    {
        string json_string = readText(path);
        JSONValue j = parseJSON(json_string);
        t.from_json(j);
    }
    else
    {
        writefln("Templates file '%s' at coal's dir not found", path);
        writeln("Generating empty template file...");
        save_templates(t);
    }
    return t;
}

private void save_templates(TemplatesFile templates)
{
    string path = get_templates_file_path();

    JSONValue j = templates.to_json();
    File file = File(path, "w");
    file.write(j.toPrettyString(JSONOptions.doNotEscapeSlashes));
    file.close();
}
