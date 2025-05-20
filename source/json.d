import std.json;
import std.array;
import std.algorithm;
import core.stdc.stdlib;
import clyd.color;
import std.stdio;

struct JsonSafe
{
    JSONValue j;
    string key;

    JsonSafe require_value()
    {
        if (key !in j)
        {
            writeln(CERR ~ "Missing required property " ~ CFOCUS ~ key ~ CERR ~ " in JSON " ~ CCLEAR);
            exit(1);
        }
        return this;
    }

    JsonSafe require_str()
    {
        require_value();
        if (j[key].type != JSONType.STRING)
        {
            writeln(CERR ~ "Property " ~ CFOCUS ~ key ~ CERR ~ " must be string " ~ CCLEAR);
            exit(1);
        }
        return this;
    }

    JsonSafe require_strarr()
    {
        require_value();
        if (j[key].type != JSONType.ARRAY)
        {
            writeln(CERR ~ "Property " ~ CFOCUS ~ key ~ CERR ~ " must be array " ~ CCLEAR);
            exit(1);
        }

        foreach (elem; j[key].array)
        {
            if (elem.type != JSONType.STRING)
            {
                writeln(
                    CERR ~ "Elements of property " ~ CFOCUS ~ key ~ CERR ~ " must be strings " ~ CCLEAR);
                exit(1);
            }
        }
        return this;
    }

    JsonSafe require_arr()
    {
        require_value();
        if (j[key].type != JSONType.ARRAY)
        {
            writeln(CERR ~ "Property " ~ CFOCUS ~ key ~ CERR ~ " must be array " ~ CCLEAR);
            exit(1);
        }
        return this;
    }

    JsonSafe require_obj()
    {
        require_value();
        if (j[key].type != JSONType.OBJECT)
        {
            writeln(CERR ~ "Property " ~ CFOCUS ~ key ~ CERR ~ " must be object " ~ CCLEAR);
            exit(1);
        }
        return this;
    }

    string str_or(string fallback)
    {
        if (key in j && j[key].type == JSONType.STRING)
        {
            return j[key].str;
        }
        return fallback;
    }

    string[] strarr_or(string[] fallback)
    {
        if (key in j && j[key].type == JSONType.ARRAY)
        {
            return j[key].array.map!(x => x.str).array;
        }
        return fallback;
    }

    JSONValue[] arr_or(JSONValue[] fallback)
    {
        if (key in j && j[key].type == JSONType.ARRAY)
        {
            return j[key].array;
        }
        return fallback;
    }

    JSONValue[string] obj_or(JSONValue[string] fallback)
    {
        if (key in j && j[key].type == JSONType.OBJECT)
        {
            return j[key].object;
        }
        return fallback;
    }

    string str()
    {
        require_str();
        return j[key].str;
    }

    string[] strarr()
    {
        require_strarr();
        return j[key].array.map!(x => x.str).array;
    }

    JSONValue[] arr()
    {
        require_arr();
        return j[key].array;
    }

    JSONValue[string] obj()
    {
        require_obj();
        return j[key].object;
    }
}

JsonSafe safe(ref JSONValue j, string key)
{
    return JsonSafe(j, key);
}
