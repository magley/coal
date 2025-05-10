import std.array;
import std.algorithm;
import std.conv;

static int[] CPP_ALLOWED_VERSIONS = [98, 11, 14, 17, 20, 23, 26];
string[] CPP_ALLOWED_VERSIONS_STR() => CPP_ALLOWED_VERSIONS.map!(
    i => to!(string)(i)).array;
