#!/bin/ksh

####################################################
# Written By: Alejandro Perez Martin
# Purpose: Normalize file names
# Jan 02, 2014
####################################################

##### Variables #####
thereAreFiles=false
check=false
lowecase=false
isNormalize=true
recursive=true
verbose=false
verboseCheck=false

##### Functions #####
error_msg() {
    echo "normalize: Missing arguments"
    echo "normalize: Syntax: 'normalize -[OPTIONS] [DIRECTORY] ... [DIRECTORY N]'"
    echo "normalize: Run 'normalize --help' for more options"
    exit 1
}

show_help() {
    printf "Usage: normalize [OPTION] ... [DIRECTORY] ...

Displays the N largest files in the specified folder/s.

If no directories are specified, the current one (./) is examined
and 10 largest files are shown.

Mandatory arguments to long options are mandatory for short options too.

   -c, --check           check if file names are normalized or not
   -h, --help            display this help and exit
   -l, --lowercase       converts filenames to lowercase
   -u, --uppercase       converts filenames to uppercase
   -r, --recursive       recursive renaming (including folders and subfolder)
   -v, --verbose         verbosely list files processed
   -V, --verbose-check   verbosely list files processed in check mode (no changes
                         are made)

Example of use:
   normalize -[c, r, l, u, v, V] directory ... directory_n
   normalize -[c, r, l, u, v, V] directory ... directory_n file ... file_n\n\n"
    exit 0
}

normnalizeFilename(){
    if [[ $lowercase = true ]]; then
        echo "$1" | iconv -t ASCII//TRANSLIT | tr [A-Z] [a-z]
    else
        echo "$1" | iconv -t ASCII//TRANSLIT | tr [a-z] [A-Z]
    fi
}

renameFile(){

    normalizedFilename=$(normnalizeFilename "$(basename "$1")")
    originalFilename="$(dirname "$1")/$(basename "$1")"
    newFilename="$(dirname "$1")/$(basename "$normalizedFilename")"

    # True if filename needs to be normalized
    [[ "$originalFilename" != "$newFilename" ]] && isNormalize=false

    # If filename is not normalized
    if [[ $isNormalize = false ]]; then

        # Check mode
        [[ $check = true ]] && echo "Filename(s) need(s) to be normalized." && removeTempFile && exit 1

        # Verbose check mode
        if [[ $verboseCheck = true ]]; then

            if [[ -d "$originalFilename" ]]; then
                echo "Directory "\'$originalFilename\'" will be renamed as "\'$newFilename\'""
            else
                echo "File "\'$originalFilename\'" will be renamed as "\'$newFilename\'""
            fi

        else

            # Renaming mode
            mv "$originalFilename" "$newFilename"

            # Verbose renaming mode
            if [[ $verbose = true ]]; then
                echo "File "$originalFilename" was renamed as "$newFilename""
            fi

        fi

    fi
}

removeTempFile(){
    [[ -f "$temporaryFile" ]] && rm -f "$temporaryFile"
}


# Ensures that at least one parameter is received
[[ $# -lt 1 ]] && error_msg


##### Options #####
while getopts ":c(check):r(recursive):u(uppercase):l(lowercase):h(help):v(verbose):V(verbose-check)" option
do
    case $option in
        h)  show_help ;;
        c)  check=true ;;
        r)  recursive=true ;;
        l)  lowercase=true ;;
        u)  lowercase=false ;;
        v)  verbose=true ;;
        V)  verboseCheck=true ;;
        *)  echo "normalize: invalid option '-$OPTARG'"
            echo "Try 'normalize --help' for more information."
            return 1 ;;
    esac
done

shift $(( OPTIND - 1 ))


##### Search #####
for file in "$@"; do

    if [[ -d "$file" || -f "$file" ]]; then

        thereAreFiles=true # True if a file or directory is specified as argument

        if [[ $recursive = true && -d "$file" ]]; then

            temporaryFile="/tmp/temporaryList"

            # Rename files and folders
            find "$file" -type f > "$temporaryFile"

            # Invert sort to rename subfolders first
            find "$file" -type d | sort -r >> "$temporaryFile"

            while read line; do
                renameFile "$line"
            done < "$temporaryFile"

        else
            renameFile "$file"
        fi

    else
        echo "(ERROR): Filetype not allowed or not exists."
    fi

done

# Removes temporary file if it was created
removeTempFile

# Error message if no files or directories are specified as arguments
[[ $thereAreFiles != true ]] && error_msg

# Show message if filenames don't need to be normalized
if [[ $isNormalize = true ]]; then
    echo "Filenames are already normalized."
    exit 0
fi

exit 0
