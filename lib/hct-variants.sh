#! /bin/sh

readonly progName='variants'
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the variants, e.g. traditional, simplified or semantic variants, of Han characters, aka Chinese characters."

readonly SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
readonly IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"
readonly VARIANTS_FILE="$SOURCE_DIR/../Unihan/Unihan_Variants.txt"

QUIET=false
VARIANT_KEY='kSimplifiedVariant'

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-simplify -o qsth -l "quiet,simplified,traditional,help" -- "$@")

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
        -s | --simplified )
            VARIANT_KEY='kSimplifiedVariant'; shift ;;
        -t | --traditional )
            VARIANT_KEY='kTraditionalVariant'; shift ;;
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

# Deal with an invalid IDS database file
if [[ ! -e $IDS_FILE ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: IDS database file not found, aborting" >&2
    fi
    exit 3
fi
# Deal with invalid Variants files
if [[ ! -e $VARIANTS_FILE ]]; then
    if [[ $QUIET == false ]]; then
        echo "hct-$progName: Unihan Variants file not found, aborting" >&2
    fi
    exit 3
fi

function get_character_variants {
    local givenChar=$1

    # Only accept one character at a time
    [ ${#givenChar} != 1 ] && return 1

    # Check if the given character is present in the
    # IDS database, and if so, get its unicode number
    local charUnicode
    charUnicode=$(grep -P "\t$givenChar\t" "$IDS_FILE" | sed "s/\t.*//")
    [[ -z $charUnicode ]] && return 2

    # Check if the given character is present in the Variants database
    ! grep -q "^$charUnicode" "$VARIANTS_FILE" && return 3

    return 0
}

variants=$(get_character_variants "$INPUT")
echo "$variants"
