# BashDebug

A bash debugging helper.
This runs bash scripts with xtrace, verbose, and/or noexec set to provide
debugging info, with colorization, extra formatting, and optional line
filtering.


## Command Help
```
Usage:
    bashdebug.sh -h | -v
    bashdebug.sh [-c | -n | -t | -V] [-f pat] SCRIPT [--] ARGS

Options:
    ARGS                    : Arguments for the script.
    SCRIPT                  : File path for bash script to debug.
    -h,--help               : Show this message.
    -n,--noexec             : Uses the -xvn flag for bash.
                              Sets the xtrace, verbose, and noexec
                              options.
    -c,-t,--test,--compile  : Uses the -n flag for bash.
                              Sets the noexec option.
                              Tests if the script will compile.
                              Does not actually execute the commands.
    -f pat,--filter pat     : Filter output lines using text/regex.
                              Like running `bashdebug.sh | grep -E pat`.
    -V,--verbose            : Use the -xv flag for bash.
                              Sets the xtrace and verbose options.
                              Prints script lines as they are read,
                              and expands lines as they are executed.
    -v,--version            : Show bashdebug version and exit.

The default action runs the script with `bash -x`, which expands the
lines as they are executed.
A fancy PS4 is set, to show the file, line, and function name.

If bashdebug.sh args conflict with the script's arguments, you can use
-- to seperate the script's arguments from bashdebug.sh arguments.
```

## Colors

Colors can be set by defining them in a BASH file called  `bashdebug_colorrc`,
located beside the `bashdebug.sh` script, or at `~/bashdebug_colorrc`. The
color definitions are sourced like a regular script. The following colors
can be defined:

* `colorsymbol`: Color for `PS4` and other symbols. Default: `$cyan`
* `colorfile`: Color for file names. Default: `$lightblue`
* `colorlineno`: Color for line numbers. Default: `$magenta`
* `colorfunc`: Color for function names. Default: `$green`
* `colortext`: Color for normal output. Default: `$nc` (no color)


## Usage

Just pass the script and any arguments to `bashdebug.sh` and watch the output.

```bash
# Basic usage:
bashdebug myscript.sh --  "Hello"

# Filtering lines by a function name:
bashdebug -f myfunc myscript.sh -- "Hello"
```
