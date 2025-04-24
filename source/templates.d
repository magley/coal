import cli;
import std.file;
import std.json;
import std.algorithm;
import std.array;
import std.path;
import std.stdio;
import core.stdc.stdlib;

struct Template
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
            Template t;
            t.from_json(j);
            return t;
        }

        templates = j["templates"].array().map!(t => template_from_json(t)).array();
    }
}

void do_new_template(const ref Command_template_new cmd)
{
    Template t;
    t.name = cmd.name.value;
    t.path = cmd.path.value;
    t.description = cmd.desc.value;

    TemplatesFile templates = load_templates();
    if (templates.templates.any!(o => o.name == t.name))
    {
        writefln("A template called %s already exists", t.name);
        exit(1);
    }

    templates.templates ~= t;
    save_templates(templates);
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
