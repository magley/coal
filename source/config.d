import std.array;
import std.algorithm;
import std.conv;

static int[] CPP_ALLOWED_VERSIONS = [98, 11, 14, 17, 20, 23, 26];
string[] CPP_ALLOWED_VERSIONS_STR() => CPP_ALLOWED_VERSIONS.map!(
    i => to!(string)(i)).array;

string[] ALLOWED_BUILD_MODES = [
    "none", "debug", "release", "minsize", "releasedebug"
];

string[][string] DEFAULT_COMPILER_FLAGS_DEFAULT() => [
    "none": [],
    "debug": ["O0", "g", "DDEBUG"],
    "release": ["O3", "DNDEBUG"],
    "minsize": ["Os", "DNDEBUG"],
    "releasedebug": ["O2", "g", "DNDEBUG"],
];
