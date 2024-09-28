#! /bin/sh

readonly progName='variants'
readonly progVersion=0.9
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the variants, i.e. traditional, simplified or semantic variants, of Han characters, aka Chinese characters.

Input:
  A single input argument is accepted, and it must be one of three types:
  A single character, a file containing a list of single characters separated
  by newlines, or a '-' character to allow reading from the stdin stream.
  If the input argument is longer than one character, it is assumed to be a file.

Output:
  For a single character: print the variants of the chosen type to the stdout stream;
    if more than one variant is available, separate the options with a single blankspace.
  For a character list: for each of the listed characters, print the character and
    its variants separated by a single tab character to the stdout stream; if more
    than one variant is available, separate the options with a single blankspace.

Options:
  -q, --quiet        suppress error messages from the stderr stream
      --semantic     query for semantic variants of the given character
      --simplified   query for simplivied variants of the given character
      --traditional  query for traditional variants of the given character
  -V, --version      show version information and exit
  -h, --help         show this help message and exit

  when multiple options are specified, out of 'semantic', 'simplified'
  and 'traditional', only the last given option is considered; when
  none of these options is specified, the 'simplified' option is implied"

readonly SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
readonly IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"
readonly VARIANTS_FILE="$SOURCE_DIR/../Unihan/Unihan_Variants.txt"

QUIET=false
USED_VARIANT='simplified'

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-simplify -o q''''''Vh -l "quiet,semantic,simplified,traditional,version,help" -- "$@")

# Deal with invalid command line arguments
if [ $? != 0 ]; then
    echo "$helpHint" >&2
    exit 1
fi
eval set -- "$GIVEN_ARGS"

# Process the command line arguments
while true; do
    case "$1" in
        -q | --quiet )
            QUIET=true; shift ;;
        --semantic )
            USED_VARIANT='semantic'; shift ;;
        --simplified )
            USED_VARIANT='simplified'; shift ;;
        --traditional )
            USED_VARIANT='traditional'; shift ;;
        -V | --version )
            echo "hct $progVersion"; exit 0 ;;
        -h | --help )
            echo "$helpText"; exit 0 ;;
        -- )
            shift; break ;;
        * )
            break ;;
    esac
done

# Process the variant option
case $USED_VARIANT in
    semantic )
        VARIANT_KEY='kSemanticVariant' ;;
    simplified )
        VARIANT_KEY='kSimplifiedVariant' ;;
    traditional )
        VARIANT_KEY='kTraditionalVariant' ;;
esac

# Process the positional arguments
if [[ -z $1 ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: no input character or file provided." >&2
        echo "$helpHint" >&2
    fi
    exit 3
elif [[ -n $2 ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: only one character or file can be provided." >&2
        echo "$helpHint" >&2
    fi
    exit 3
elif [[ $1 == - ]]; then
    if [ -t 0 ]; then
        echo "htc-$progName: argument '-' specified without input on stdin." >&2
        echo "$helpHint" >&2
    else
        read -d '' INPUT
    fi
else
    if [[ ${#1} != 1 && ! -e $1 ]]; then
        if [[ $QUIET == false ]]; then
            echo "htc-$progName: input file does not exist." >&2
            echo "$helpHint" >&2
        fi
        exit 3
    else
        INPUT="$1"
    fi
fi

# Deal with an invalid IDS database file
if [[ ! -e $IDS_FILE ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: IDS database file not found, aborting" >&2
    fi
    exit 4
fi
# Deal with invalid Variants files
if [[ ! -e $VARIANTS_FILE ]]; then
    if [[ $QUIET == false ]]; then
        echo "hct-$progName: Unihan Variants file not found, aborting" >&2
    fi
    exit 4
fi

function get_character_variants {
    local givenChar=$1

    # Only accept one character at a time
    [ ${#givenChar} != 1 ] && return 10

    # Check if the given character is present in the
    # IDS database, and if so, get its unicode number
    local charUnicode
    charUnicode=$(grep -P "\t$givenChar\t" "$IDS_FILE" | sed "s/\t.*//")
    [[ -z $charUnicode ]] && return 20

    # Check if the given character is present in the Variants database
    ! grep -q "^$charUnicode" "$VARIANTS_FILE" && return 21

    # Get the entry's text for the chosen variant type; this consists of one or
    # more unicode numbers separated by blankspaces, i.e. U+1234 plus an extra
    # info source info field for 'semantic' variants in the form of <kSource1
    local charVariants
    charVariants=$(grep "$charUnicode.$VARIANT_KEY" "$VARIANTS_FILE" | sed "s/.*\t//")
    [[ -z $charVariants ]] && return 22

    # For 'simplified' and 'traditional' variants, remove from
    # the retrieved unicode numbers the unicode number of the
    # given character itself, which is present for some entries
    if [[ $VARIANT_KEY == kSimplifiedVariant|| $VARIANT_KEY == kTraditionalVariant ]]; then
        charVariants=$(echo "$charVariants" | sed "s/$charUnicode *//")
        [[ -z $charVariants ]] && return 23
    fi

    # For 'semantic' variants, put the reference source for the given
    # variant inside of parentheses and remove the 'k' from the sources
    if [[ $VARIANT_KEY == kSemanticVariant ]]; then
        charVariants=$(echo "$charVariants" | sed "s/<\([^ ]*\) /(\1) /g")
        charVariants=$(echo "$charVariants" | sed "s/<\([^ ]*\)$/(\1)/g")
        charVariants=$(echo "$charVariants" | sed "s/(k/(/g")
        charVariants=$(echo "$charVariants" | sed "s/,k/,/g")
    fi

    # Format the unicode numbers to print them
    # with echo, i.e., change from U+1234 to \U1234
    charVariants=$(echo "$charVariants" | sed 's/U+/\\U/g')

    echo -e "$charVariants"
    return 0
}

# If input is a file
if [[ -e $INPUT ]]; then
    lineCount=$(sed -n '$=' "$INPUT")
    processCount=0
    if [ ! -t 1 ]; then
        echo "# Used options"
        echo "# USED_VARIANT=$USED_VARIANT"
    fi
    while read testedChar; do
        ((processCount++))
        echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
        variants=$(get_character_variants "$testedChar")
        exitCode=$?
        if [ $exitCode == 0 ]; then
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$variants"
        else
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$exitCode"
        fi
    done < "$INPUT"
    echo -e "\r\033[0KProcessing done" >&2
    exit 0
# If input is a single character
elif [[ ${#INPUT} == 1 ]]; then
    variants=$(get_character_variants "$INPUT")
    exitCode=$?
    if [[ $exitCode == 0 ]]; then
        echo "$variants"
    elif [[ $QUIET == false ]]; then
        case $exitCode in
            20)
                echo "The given character is not present in the IDS database." >&2 ;;
            21)
                echo "The given character is not present in the Variants database." >&2 ;;
            22)
                echo "The given character has no variants for the selected type." >&2 ;;
            23)
                echo "The given character has no valid variants for the selected type." >&2 ;;
        esac
    fi
    exit $exitCode
# Otherwise, input comes from stdin
else
    lineCount=$(echo "$INPUT" | sed -n '$=')
    processCount=0
    if [ ! -t 1 ]; then
        echo "# Used options"
        echo "# USED_VARIANT=$USED_VARIANT"
    fi
    while read testedChar; do
        ((processCount++))
        echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
        variants=$(get_character_variants "$testedChar")
        exitCode=$?
        if [ $exitCode == 0 ]; then
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$variants"
        else
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$exitCode"
        fi
    done < <(echo "$INPUT")
    echo -e "\r\033[0KProcessing done" >&2
    exit 0
fi
