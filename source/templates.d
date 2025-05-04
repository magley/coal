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
import init;
import clyd.command;

void do_list_template(Command cmd)
{
    TemplatesFile templates = load_templates();

    if (cmd.args["verbose"].is_set_flag)
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

void do_new_template(Command cmd)
{
    string name = cmd.args["name"].value;
    string path = cmd.args["path"].value;
    string desc = cmd.args["desc"].value;

    Template t = new Template();
    t.name = name;
    t.path = path;
    t.description = desc;

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

void do_clone_from_template(Command cmd)
{
    ensure_coalfile_not_exists(); // At current directory.
    // This is also called when initializing a new project,
    // which may or may not happen later on in this fuinction.
    // It's not a big deal if we call it multiple times, but
    // it may cause unexpected issues in the future.

    import project;
    import input;

    string template_name = cmd.args["template"].value;
    string name = cmd.args["name"].value;
    string src = cmd.args["src"].value_or(null);
    string build = cmd.args["build"].value_or(null);
    string generator = cmd.args["generator"].value_or(null);

    const TemplatesFile templates = load_templates();

    // [1] Load template.

    const Template t = templates.get_template(template_name);
    if (t is null)
    {
        writefln(CERR ~ "Unknown template " ~ CFOCUS ~ "%s" ~ CCLEAR, template_name);
        exit(1);
    }

    writeln(""
            ~ CTRACE ~ "    [1/3 coal template] "
            ~ CINFO ~ "Creating project "
            ~ CFOCUS ~ name
            ~ CINFO ~ " from template "
            ~ CFOCUS ~ template_name
            ~ CCLEAR);

    // [2] Create project file.
    //
    // We *could* copy all files and then construct a project, but if this
    // function fails, you're left with a bunch of files and an invalid project.
    // One case where the function fails is if a coalfile is missing and you
    // didn't specify some parameter properly. It's not a good idea to copy
    // first, do logic, and then delete files in case of an error.

    Project p;

    const bool brand_new_coalfile = !coalfile_exists(t.path);
    if (!brand_new_coalfile)
    {
        writeln(
            ""
                ~ CTRACE ~ "    [2/3 coal template] "
                ~ CINFO ~ "Cloning coalfile from template "
                ~ CFOCUS ~ template_name
                ~ CCLEAR);

        Project template_project = load(t.path);
        p = template_project.clone();
        p.name = name;
    }
    else
    {
        import init;

        writeln(""
                ~ CTRACE ~ "    [2/3 coal template] "
                ~ CINFO ~ "Template "
                ~ CFOCUS ~ template_name
                ~ CINFO ~ " has no coalfile (expected "
                ~ CCLEAR ~ buildPath(t.path, "coalfile")
                ~ CINFO ~ "). Generating a new coal project"
                ~ CCLEAR);

        p = create_new_project(cmd);
    }

    // [3] Override src, build etc. if provided and if not a brand new coalfile.

    if (!brand_new_coalfile)
    {
        if (src !is null)
        {
            writeln(""
                    ~ CWARN ~ "        Overriding source folders from "
                    ~ CINFO ~ p.source_dirs.join(
                        ", ")
                    ~ CWARN ~ " to "
                    ~ CINFO ~ src
                    ~ CCLEAR);

            p.source_dirs = [src];
        }
        if (build !is null)
        {
            writeln(
                ""
                    ~ CWARN ~ "        Overriding build folder from "
                    ~ CINFO ~ p.build_dir
                    ~ CWARN ~ " to "
                    ~ CINFO ~ build
                    ~ CCLEAR);

            p.build_dir = build;
        }
        if (generator !is null)
        {
            writeln(""
                    ~ CWARN ~ "        Overriding generator from "
                    ~ CINFO ~ p.generator
                    ~ CWARN ~ " to "
                    ~ CINFO ~ generator
                    ~ CCLEAR);

            p.generator = generator;
        }
    }

    // [4] Copy files.

    {
        import fileio;

        writeln(""
                ~ CTRACE ~ "    [3/3 coal template] "
                ~ CINFO ~ "Copying files from template "
                ~ CFOCUS ~ template_name
                ~ CINFO ~ " into project "
                ~ CFOCUS ~ p.name
                ~ CINFO ~ "\n        ("
                ~ CCLEAR ~ absolutePath(
                    t.path)
                ~ CINFO ~ " -> "
                ~ CCLEAR ~ absolutePath(".")
                ~ CINFO ~ ")"
                ~ CCLEAR);

        // Prevent infinite loops.
        {
            string template_path = t.path;
            string project_path = ".";

            if (is_subdirectory(template_path, project_path))
            {
                writefln(
                    ""
                        ~ CERR ~ "Cannot clone template here: project "
                        ~ CFOCUS ~ p.name
                        ~ CERR ~ " is in child directory of template "
                        ~ CFOCUS ~ t.name
                        ~ CINFO ~ " (cloning would cause an infinite loop)"
                        ~ CCLEAR);
                exit(1);
                return;
            }
        }

        // We ignore `coalfile` here because we have already created one from a
        // Project. If we were to copy the coalfile here, it would override any
        // changes (for example: project name).
        copy_folder_contents(t.path, ".", [".git", p.build_dir], ["coalfile"]);
    }

    // [5] After the files have been copied, we can optionally create a stub
    // file and save the project (thus creating the final coalfile). also save
    // the new coalfile.

    if (brand_new_coalfile)
    {
        create_stub(p);
    }
    save(p, ".");

    // [6] Copy coalfile.private from template (if any). We ignored the source
    // build dir entirely, including coalfile.private, so this has to be
    // explicit. This goes after save(p) because then we know for sure that the
    // project's build directory has been created, which is needed for copy() to
    // not throw.

    {
        string src_path = buildPath(t.path, p.build_dir, "coalfile.private");
        if (exists(src_path))
        {
            string dst_path = buildPath(p.build_dir, "coalfile.private");
            copy(src_path, dst_path);
        }
    }

    after_init(p.name);
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
