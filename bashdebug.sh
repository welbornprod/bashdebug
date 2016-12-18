#!/bin/bash

# Bash script debugger, stolen (but rewritten) from:
#   http://wiki.bash-hackers.org/scripting/debuggingtips
# -Christopher Welborn 11-01-2016
appname="bashdebug"
appversion="0.1.0"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"
# Use color definition file.
default_colrdef_file="${appdir}/bashdebug_colorrc"
colrdef_file=~/bashdebug_colorrc

function debug_cmd {
    local script=$1
    shift
    declare -a scriptargs=("$@")
    [[ -n "$script" ]] || fail "No script name given!"
    [[ -f "$script" ]] || fail "Script not found: $script"
    # Setup debugging PS4.
    PS4="${nc}\
${colorsymbol}+\
${colorsymbol}(\
${colorfile}"'${BASH_SOURCE##*/}'"\
${nc}:\
${colorlineno}"'$(printf "%5s" "${LINENO}")'"\
${colorsymbol})\
${nc}: \
${colorfunc}"'$(printf "%-15s" "${FUNCNAME[0]}()")'"\
${nc}: \
${colortext}"
    export PS4
    trap reset_colors INT
    printf_err "\nRunning: bash %s %s %s\n\n" "${bashflags[*]}" "$script" "${scriptargs[*]}"
    bash "${bashflags[@]}" "$script" "${scriptargs[@]}"
}

function define_colors {
    # shellcheck disable=SC2034
    if [[ -f "$colrdef_file" ]]; then
        source "$colrdef_file"
    elif [[ -f "$default_colrdef_file" ]]; then
        source "$default_colrdef_file"
    else
        # basic color definitions
        black="$(tput setaf 0)"
        blue="$(tput setaf 4)"
        cyan="$(tput setaf 6)"
        darkgrey="$(tput bold ; tput setaf 0)"
        green="$(tput setaf 2)"
        lightblue="$(tput setaf 4)"
        lightcyan="$(tput bold ; tput setaf 6)"
        lightgreen="$(tput bold ; tput setaf 2)"
        lightgrey="$(tput setaf 7)"
        lightred="$(tput bold ; tput setaf 1)"
        magenta="$(tput setaf 5)"
        pink="$(tput bold ; tput setaf 5)"
        red="$(tput setaf 1)"
        white="$(tput bold ; tput setaf 7)"
        whitedull="\033[38;5;251m"
        whitedullbold="\033[1m\033[38;5;251m"
        yellow="$(tput setaf 3)"
        # reset code.
        nc="$(tput sgr0)"
    fi
    export black blue cyan darkgrey green
    export lightblue lightcyan lightgreen lightgrey lightred
    export magenta pink red white whitedull yellow nc

    # Codes used in PS4
    [[ -n $colorsymbol ]] || colorsymbol=$cyan
    [[ -n $colorfile ]] ||  colorfile=$lightblue
    [[ -n $colorlineno ]] ||  colorlineno=$magenta
    [[ -n $colorfunc ]] ||  colorfunc=$green
    [[ -n $colortext ]] ||  colortext=$nc
    export colorfile colorlineno colorfunc
}

function echo_err {
    # Echo to stderr.
    echo -e "$@" 1>&2
}

function fail {
    # Print a message to stderr and exit with an error status code.
    echo_err "$@"
    exit 1
}

function fail_usage {
    # Print a usage failure message, and exit with an error status code.
    print_usage "$@"
    exit 1
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Runs bash scripts with xtrace, verbose, and/or noexec set to provide
    debugging info. A fancy PS4 is set to show the file, line, and function
    name.


    Usage:
        $appscript -h | -v
        $appscript [-c | -n | -t | -V] [-f pat] SCRIPT [--] ARGS

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
                                  Like running \`bashdebug.sh | grep -E pat\`.
        -V,--verbose            : Use the -xv flag for bash.
                                  Sets the xtrace and verbose options.
                                  Prints script lines as they are read,
                                  and expands lines as they are executed.
        -v,--version            : Show $appname version and exit.

    The default action runs the script with \`bash -x\`, which expands the
    lines as they are executed.

    If $appscript args conflict with the script's arguments, you can use
    -- to seperate the script's arguments from $appscript arguments.
    "
}

function printf_err {
    # Printf, to stderr.
    # shellcheck disable=SC2059
    # ...I know shellcheck, no variables in printf. Except for this one.
    printf "$@" 1>&2
}

function reset_colors {
    # Print the nc code, to reset colors.
    echo -e "$nc"
}

(( $# > 0 )) || fail_usage "No arguments!"

declare -a bashflags userargs
in_extra_args=0
filter_pat=''
in_filter_arg=0
for arg; do
    case "$arg" in
        "--" )
            in_extra_args=1
            ;;
        "-f"|"--filter" )
            in_filter_arg=1
            ;;
        "-h"|"--help" )
            ((in_extra_args)) && {
                userargs+=("$arg")
                continue
            }
            print_usage ""
            exit 0
            ;;
        "-n"|"--noexec" )
            ((in_extra_args)) && {
                userargs+=("$arg")
                continue
            }
            bashflags=("-x" "-v" "-n")
            ;;
        "-c"|"-t"|"--compile"|"--test" )
            ((in_extra_args)) && {
                userargs+=("$arg")
                continue
            }
            bashflags=("-n")
            ;;
        "-V"|"--verbose" )
            ((in_extra_args)) && {
                userargs+=("$arg")
                continue
            }
            bashflags=("-x" "-v")
            ;;
        "-v"|"--version" )
            ((in_extra_args)) && {
                userargs+=("$arg")
                continue
            }
            echo -e "$appname v. $appversion\n"
            exit 0
            ;;
        *)
            if ((in_filter_arg)); then
                [[ -z "$filter_pat" ]] || fail_usage "Only one -f allowed."
                filter_pat=$arg
                in_filter_arg=0
            else
                userargs+=("$arg")
            fi
    esac
done
((${#userargs[@]})) || fail_usage "No script name given!"
define_colors
reset_colors

((${#bashflags[@]})) || bashflags=("-x")
userscript="${userargs[0]}"
userargs=("${userargs[@]:1}")
if [[ -n "$filter_pat" ]]; then
    debug_cmd "$userscript" "${userargs[@]}" 2>&1 | grep -i -E "$filter_pat"
else
    debug_cmd "$userscript" "${userargs[@]}"
fi
reset_colors
