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
import input;

void do_list_templates(const ref Command_template_list cmd)
{
    TemplatesFile templates = load_templates();

    if (cmd.verbose.get)
    {
        foreach (const ref t; templates.templates)
        {
            writefln("%s\n\t%s\n\t%s", t.name, t.description, t.path);
        }
    }
    else
    {
        writeln(join(templates.templates.map!(t => t.name), ", "));
    }
}

void do_new_template(const ref Command_template_new cmd)
{
    Template t = new Template();
    t.name = cmd.name.get;
    t.path = cmd.path.get;
    t.description = cmd.desc.get;

    if (!exists(t.path))
    {
        writefln(CERR ~ "Path " ~ CFOCUS ~ "%s" ~ CERR ~ " doesn't exist" ~ CCLEAR, t.path);
        exit(1);
    }
    t.path = absolutePath(t.path).dirName().replace("\\", "/");
    if (!isDir(t.path))
    {
        writefln(CERR ~ "Path " ~ CFOCUS ~ "%s" ~ CERR ~ " is not a directory" ~ CCLEAR, t.path);
        exit(1);
    }

    TemplatesFile templates = load_templates();
    if (templates.templates.any!(o => o.name == t.name))
    {
        writefln(CERR ~ "Template " ~ CFOCUS ~ "%s" ~ CERR ~ " already exists" ~ CCLEAR, t.name);
        exit(1);
    }

    templates.templates ~= t;
    save_templates(templates);
}

void do_spawn_from_template(const ref Command_template_spawn cmd)
{
    import project;
    import input;

    const TemplatesFile templates = load_templates();

    // [1] Load template.

    const Template t = templates.get_template(cmd.template_name.get);
    if (t is null)
    {
        writefln(CERR ~ "Unknown template " ~ CFOCUS ~ "%s" ~ CCLEAR, cmd.template_name.get);
        exit(1);
    }

    writeln(""
            ~ CTRACE ~ "    [1/3 coal template] "
            ~ CINFO ~ "Creating project "
            ~ CFOCUS ~ cmd.project_name.get
            ~ CINFO ~ " from template "
            ~ CFOCUS ~ cmd.template_name.get
            ~ CCLEAR);

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
        writeln(
            ""
                ~ CTRACE ~ "    [2/3 coal template] "
                ~ CINFO ~ "Cloning coalfile from template "
                ~ CFOCUS ~ cmd.template_name.get
                ~ CCLEAR);

        Project template_project = load(t.path);
        p = template_project.clone();
        p.name = cmd.project_name.get();
        save(p, ".");
    }
    else
    {
        import init;

        writeln(""
                ~ CTRACE ~ "    [2/3 coal template] "
                ~ CINFO ~ "Template "
                ~ CFOCUS ~ cmd.template_name.get
                ~ CINFO ~ " has no coalfile (expected "
                ~ CCLEAR ~ buildPath(t.path, "coalfile")
                ~ CINFO ~ "). Generating a new coal project"
                ~ CCLEAR);

        p = do_init(cmd);
    }
    assert(exists("./coalfile"));

    // [3] Copy files.

    {
        import fileio;

        writeln(""
                ~ CTRACE ~ "    [3/3 coal template] "
                ~ CINFO ~ "Copying files from template "
                ~ CFOCUS ~ cmd.template_name.get
                ~ CINFO ~ " into project "
                ~ CFOCUS ~ p.name
                ~ CINFO ~ "\n        ("
                ~ CCLEAR ~ absolutePath(
                    t.path)
                ~ CINFO ~ " -> "
                ~ CCLEAR ~ absolutePath(".")
                ~ CINFO ~ ")"
                ~ CCLEAR);

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
        writefln(CWARN ~ "Templates file " ~ CFOCUS ~ "%s" ~ CWARN ~ " not found", path);
        writeln("Generating empty template file..." ~ CCLEAR);
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
