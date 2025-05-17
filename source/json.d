import std.json;
import std.array;
import std.algorithm;

string get_string(ref JSONValue j, string key, string fallback)
{
    if (key in j)
    {
        return j[key].str;
    }
    return fallback;
}

string[] get_strings(ref JSONValue j, string key, string[] fallback)
{
    if (key in j)
    {
        return j[key].array.map!(x => x.str).array;
    }
    return fallback;
}

JSONValue[] get_arr(ref JSONValue j, string key)
{
    if (key in j)
    {
        if (j[key].type == JSONType.ARRAY)
        {
            return j[key].array;
        }
    }
    return [];
}

JSONValue[string] get_obj(ref JSONValue j, string key)
{
    if (key in j)
    {
        if (j[key].type == JSONType.OBJECT)
        {
            return j[key].object;
        }
    }
    return null;
}
