#! /bin/sh

readonly progName='composition'
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the composition options for Chinese characters.

Input:
  A single input argument is accepted, and it must be one of two types:
  A single character or a file containing a list of single characters separated by newlines.
  If the input argument is longer than one character, it is assumed to be a file.

Output:
  For a single character: print the composition for the given character
    to the stdout stream; if more than one composition option is available,
    separate the options with a single tab character.
  For a character list: for each of the listed characters, print the character and its
    composition separated by a single tab character to the stdout stream; if more than
    one composition option is available, separate the options with a single tab char.

Options:
  -q, --quiet       suppress error messages from the stderr stream
  -w, --wiktionary  retrieve the composition information from Wiktionary
                    instead of the default local IDS database
  -h, --help        show this help message and exit"

SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"

QUIET=false
USE_WIKTIONARY=false

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-$progName -o qwh -l "quiet,wiktionary,help" -- "$@")

# Deal with invalid command line arguments
if [ $? != 0 ]; then
    echo "$helpHint"
    exit 1
fi
eval set -- "$GIVEN_ARGS"

# Process the command line arguments
while true; do
    case "$1" in
        -q | --quiet )
            QUIET=true; shift ;;
        -w | --wiktionary )
            USE_WIKTIONARY=true; shift ;;
        -h | --help )
            echo "$helpText"; exit 0 ;;
        -- )
            shift; break ;;
        * )
            break ;;
    esac
done

# Process the positional arguments
if [[ -z $1 ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: no input character or file provided." >&2
        echo "$helpHint" >&2
    fi
    exit 2
elif [[ -n $2 ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: only one character or file can be provided." >&2
        echo "$helpHint" >&2
    fi
    exit 2
else
    if [[ ! -e $1 && ${#1} != 1 ]]; then
        if [[ $QUIET == false ]]; then
            echo "htc-$progName: input file does not exist." >&2
            echo "$helpHint" >&2
        fi
        exit 2
    else
        INPUT="$1"
    fi
fi

get_character_composition_wikt () {
    local givenChar=$1

    # Only accept one character at a time
    [ ${#givenChar} != 1 ] && return 10

    # Curl the wiktionary page for the given character
    local url="https://en.wiktionary.org/wiki/$givenChar"
    local html
    html=$(curl -# -L "${url}" 2> '/dev/null')

    # Check if the page has a 'Han character' section and the
    # corresponding line where the character composition should be
    local hanCharacterHeadword
    hanCharacterHeadword=$(echo "$html" | grep -m 1 -A 15 '<div class="mw-heading mw-heading3"><h3 id="Han_character">Han character</h3>')
    hanCharacterHeadword=$(echo "$hanCharacterHeadword" | grep '<span class="headword-line"><strong class="Hani headword" lang="mul">')
    [[ -z $hanCharacterHeadword ]] && return 21

    # Check if there is composition information present
    local compositionString
    compositionString=$(echo "$hanCharacterHeadword" | grep 'composition')
    compositionString=$(echo "$compositionString" | sed 's/.*composition//')
    [[ -z $compositionString ]] && return 22

    # Extract the composition string for the character
    # Remove the html tags
    compositionString=$(echo "$compositionString" | sed 's/<[^>]*>//g')
    # Remove the first blankspace
    compositionString=$(echo "$compositionString" | sed 's/^ //')
    # Remove the last solitary parenthesis
    compositionString=$(echo "$compositionString" | sed 's/)$//')
    # Separate the different composition options by a tab character
    compositionString=$(echo "$compositionString" | sed "s/ or /\t/g")

    echo "$compositionString"
    return 0
}

get_character_composition_ids () {
    local givenChar=$1

    # Only accept one character at a time
    [ ${#givenChar} != 1 ] && return 10

    # Check if the given character is present in the IDS database
    local compositionString
    compositionString=$(grep -P "\t$givenChar\t" "$IDS_FILE")
    [[ -z $compositionString ]] && return 11

    # Check if the given character has at least one valid composition option.
    # Remove the text before the composition options
    compositionString=$(echo "$compositionString" | sed "s/.*$givenChar\t//")
    # Remove the notes some entries might have, i.e., the text after a * sign
    compositionString=$(echo "$compositionString" | sed "s/\t\*.*//")
    # Remove composition options with subtraction, mirror, rotation
    # and variation IDCs, i.e., compositions with ㇯⿾⿿〾 in them
    while [[ -n $(echo "$compositionString" | sed -n "/\t[^\t]*[㇯⿾⿿〾][^\t]*\t/p") ]]; do
        compositionString=$(echo "$compositionString" | sed "s/\t[^\t]*[㇯⿾⿿〾][^\t]*\t/\t/")
    done
    compositionString=$(echo "$compositionString" | sed "s/^[^\t]*[㇯⿾⿿〾][^\t]*\t//")
    compositionString=$(echo "$compositionString" | sed "s/\t[^\t]*[㇯⿾⿿〾][^\t]*$//")
    compositionString=$(echo "$compositionString" | sed "s/^[^\t]*[㇯⿾⿿〾][^\t]*$//")
    # Remove composition options with unrepresentable components, i.e. with ？ in them
    while [[ -n $(echo "$compositionString" | sed -n "/\t[^\t]*？[^\t]*\t/p") ]]; do
        compositionString=$(echo "$compositionString" | sed "s/\t[^\t]*？[^\t]*\t/\t/")
    done
    compositionString=$(echo "$compositionString" | sed "s/^[^\t]*？[^\t]*\t//")
    compositionString=$(echo "$compositionString" | sed "s/\t[^\t]*？[^\t]*$//")
    compositionString=$(echo "$compositionString" | sed "s/^[^\t]*？[^\t]*$//")
    # Remove composition options with unencoded components, i.e. with {} in them
    while [[ -n $(echo "$compositionString" | sed -n "/\t[^\t]*[{}][^\t]*\t/p") ]]; do
        compositionString=$(echo "$compositionString" | sed "s/\t[^\t]*[{}][^\t]*\t/\t/")
    done
    compositionString=$(echo "$compositionString" | sed "s/^[^\t]*[{}][^\t]*\t//")
    compositionString=$(echo "$compositionString" | sed "s/\t[^\t]*[{}][^\t]*$//")
    compositionString=$(echo "$compositionString" | sed "s/^[^\t]*[{}][^\t]*$//")
    [[ -z $compositionString ]] && return 12

    # Remove all the ^ and $ characters
    compositionString=$(echo "$compositionString" | sed 's/[$^]//g')

    echo "$compositionString"
    return 0
}

# If input is a file
if [[ -e $INPUT ]]; then
    lineCount=$(sed -n '$=' "$INPUT")
    processCount=0
    while read testedChar; do
        ((processCount++))
        echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
        if [[ $USE_WIKTIONARY == true ]]; then
            composition=$(get_character_composition_wikt "$testedChar")
        else
            composition=$(get_character_composition_ids "$testedChar")
        fi
        exitCode=$?
        if [ $exitCode == 0 ]; then
            if [ -t 1 ]; then
                echo -e "\r\033[0K$testedChar\t$composition"
            else
                echo -e "$testedChar\t$composition"
            fi
        else
            if [ -t 1 ]; then
                echo -e "\r\033[0K$testedChar\t$exitCode"
            else
                echo -e "$testedChar\t$exitCode"
            fi
        fi
    done < "$INPUT"
    echo -e "\r\033[0KProcessing done" >&2
# Otherwise it's a single character
else
    if [[ $USE_WIKTIONARY == true ]]; then
        composition=$(get_character_composition_wikt "$testedChar")
    else
        composition=$(get_character_composition_ids "$INPUT")
    fi
    exitCode=$?
    if [[ $exitCode == 0 ]]; then
        echo "$composition"
    elif [[ $QUIET == false ]]; then
        case $exitCode in
            11)
                echo "The given character is not present in the IDS database." >&2 ;;
            12)
                echo "The given character does not have a valid composition option." >&2 ;;
            21)
                echo "The given character does not have a valid Wiktionary entry." >&2 ;;
            22)
                echo "The Wiktionary entry for the given character does not contain composition information." >&2 ;;
        esac
    fi
fi
