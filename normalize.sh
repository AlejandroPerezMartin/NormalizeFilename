#!/bin/ksh

####################################################
# Written By: Alejandro Perez Martin
# Purpose: Normalize file names
# Jan 02, 2014
####################################################

### Variables ###
lowecase=false
recursive=true
verbose=false
check=false

### Functions ###
error_msg() {
    echo "normaliza: Missing arguments"
    echo "normaliza: Syntax: 'normaliza -[OPTIONS] [DIRECTORY] ... [DIRECTORY N]'"
    echo "normaliza: Run 'normaliza --help' for more options"
    exit 1
}

show_help() {
    printf "Usage: normaliza [OPTION] ... [DIRECTORY] ...

Displays the N largest files in the specified folder/s.

If no directories are specified, the current one (./) is examined
and 10 largest files are shown.

Mandatory arguments to long options are mandatory for short options too.

   -c, --check       check if file names are normalized or not
   -h, --help        display this help and exit
   -l, --lowercase   converts file names to lowercase
   -u, --uppercase   converts file names to uppercase
   -w                remove withespaces
   -s                replace each input sequence of a repeated character that is
                     listed in SET1 with a single occurrence of that characte
   -r                recursive renaming (folders too)
   -t, --type        display results in Megabytes (MB)
   -v                verbose

Example of use:
   normaliza -[r, l, u, w, s, t, v] directory ... directory_n
   normaliza -[r, l, u, w, s, t, v] directory ... directory_n file ... file_n"
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

    [[ "$originalFilename" != "$newFilename" ]] && mv "$originalFilename" "$newFilename"
}



### Options ###
while getopts "ru(uppercase):l(lowercase):h(help)" option
do
    case $option in
        h)  show_help ;;
        r)  recursive=true  ;;
        l)  lowercase=true  ;;
        u)  lowercase=false ;;
        *)  echo "normaliza: invalid option '-$OPTARG'"
            echo "Try 'normaliza --help' for more information."
            return 1 ;;
    esac
done

shift $(( OPTIND - 1 ))


### Search ###
for file in "$@"; do
    if [[ -d "$file" || -f "$file" ]]; then
        if [[ $recursive=true && -d "$file" ]]; then
            temporaryFile="/tmp/temporaryList"

            # Rename regular files
            find "$file" -type f > "$temporaryFile"
            while read line; do
                renameFile "$line"
            done < "$temporaryFile"

            # Rename folders
            find "$file" -type d | sort -r > "$temporaryFile"
            while read line; do
                renameFile "$line"
            done < "$temporaryFile"

            rm -f "$temporaryFile"
        else
            renameFile "$file"
        fi
    else
        echo "(ERROR): Filetype not allowed"
    fi
done
