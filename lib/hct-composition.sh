#! /bin/sh

readonly progName='composition'
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the composition of Han characters, aka Chinese characters.

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
  -s, --source={GHMTJKPVUSBXYZ}
                    a string containing the desired source region letter(s) must be provided;
                    when used, filter out composition options that do not contain the
                    specified source letter(s); see below to see the source options;
                    this option is ignored when using the 'wiktionary' option

  -w, --wiktionary  retrieve the composition information from Wiktionary
                    instead of the default local IDS database

  -h, --help        show this help message and exit

  The differen letters and the corresponding regions to be
  chosen from for the 'source' option are the following:
  G -> China
  H -> Hong Kong SAR
  M -> Macau SAR
  T -> TCA/Taiwan
  J -> Japan
  K -> ROKorea
  P -> DPRKorea
  V -> Vietnam
  U -> Unicode
  S -> SAT
  B -> UK
  X -> Alternative IDS for same glyph structure
  Y -> UCS2003 glyphs
  Z -> Unifiable or plausible alternative form of the glyph

Environment variables:
  Environment variables are specially useful to avoid giving
  arguments for a specific option which will be used repeatedly.
  One environment variable is checked for when using this command:

  HCT_SOURCE_LETTERS, to specify an input for the 'source' option.

  The environment variables' value can be overwritten by
  specifying the corresponding command line arguments.
  Environment variables are ignored silently if they do
  not contain a valid argument for the corresponding option."

readonly SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
readonly IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"

QUIET=false
USE_WIKTIONARY=false

# Process the environment variables
if [[ -n $HCT_SOURCE_LETTERS && -z $(echo $HCT_SOURCE_LETTERS | sed 's/[GHMTJKPVUSBXYZ]//g') ]]; then
    SOURCE_LETTERS="$HCT_SOURCE_LETTERS"
fi

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-$progName -o qs:wh -l "quiet,source:,wiktionary,help" -- "$@")

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
        -s | --source )
            SOURCE_LETTERS="$2"; shift 2 ;;
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

# Process the source option letters
if [[ -n $SOURCE_LETTERS ]]; then
    if [[ -n $(echo $SOURCE_LETTERS | sed 's/[GHMTJKPVUSBXYZ]//gI') ]]; then
        if [[ $QUIET == false ]]; then
            echo "htc-$progName: invalid argument for the option 's|source'" >&2
            echo "$helpHint" >&2
        fi
        exit 2
    fi
    SOURCE_LETTERS=$(echo "$SOURCE_LETTERS" | tr '[:lower:]' '[:upper:]')
fi

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
    hanCharacterHeadword=$(echo "$html" | grep -m 1 -A 30 '<div class="mw-heading mw-heading3"><h3 id="Han_character">Han character</h3>')
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
    # Remove the last solitary parenthesis present in every composition string
    compositionString=$(echo "$compositionString" | sed 's/)$//')
    # Remove U+... and U&... inside of parentheses that are present in some compositions
    compositionString=$(echo "$compositionString" | sed 's/U[+&][^)]*)/)/g')
    # Remove the leftover 'or' inside of parentheses
    compositionString=$(echo "$compositionString" | sed "s/ or )/)/g")
    # Remove the lefover empty parentheses ()
    compositionString=$(echo "$compositionString" | sed "s/()//g")
    # Replace the ' or ', which separates different compositions, by a single tab character
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

    # Remove the text before the composition options
    compositionString=$(echo "$compositionString" | sed "s/.*$givenChar\t//")
    # Remove the notes some entries might have, i.e., the text after a * sign
    compositionString=$(echo "$compositionString" | sed "s/\t\*.*//")
    # Remove all the ^ and $ characters
    compositionString=$(echo "$compositionString" | sed 's/[$^]//g')
    # Create an array with each of the available composition options
    local compositionOptions=()
    read -a compositionOptions <<< "$compositionString"
    # Remove composition options with unrepresentable components, unencoded components, or not
    # wished IDCs, i.e. composition options that have any of the follow characters: ？{}〾㇯⿾⿿
    for idx in "${!compositionOptions[@]}"; do
        if [[ -n $(echo "${compositionOptions[idx]}" | sed -n '/[？{}〾㇯⿾⿿]/p') ]]; then
            unset "compositionOptions[$idx]"
        fi
    done
    # Check if the given character still has at least one valid composition option
    [[ -z ${compositionOptions[@]} ]] && return 12

    # If a source region was specified, filter out composition
    # options that do not have the letter of that source
    if [[ -n $SOURCE_LETTERS ]]; then
        for idx in "${!compositionOptions[@]}"; do
            if [[ -z $(echo "${compositionOptions[idx]}" | sed -n "/[$SOURCE_LETTERS]/p") ]]; then
                unset "compositionOptions[$idx]"
            fi
        done
    fi
    # Check if the given character still has at least one valid composition option
    [[ -z ${compositionOptions[@]} ]] && return 13

    echo "${compositionOptions[@]}"
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
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$composition"
        else
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$exitCode"
        fi
    done < "$INPUT"
    echo -e "\r\033[0KProcessing done" >&2
# Otherwise it's a single character
else
    if [[ $USE_WIKTIONARY == true ]]; then
        composition=$(get_character_composition_wikt "$INPUT")
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
                echo "The given character has no valid composition options." >&2 ;;
            13)
                echo "The given character has no composition options for the selected source(s)." >&2 ;;
            21)
                echo "The given character does not have a valid Wiktionary entry." >&2 ;;
            22)
                echo "The Wiktionary entry for the given character has no composition information." >&2 ;;
        esac
    fi
    exit $exitCode
fi
