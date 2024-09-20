#! /bin/sh

readonly progName='reading'
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the pronunciation for Chinese characters in different language systems.

Input:
  A single input argument is accepted, and it must be one of two types:
  A single character or a file containing a list of single characters separated by newlines.
  If the input argument is longer than one character, it is assumed to be a file.

Output:
  For a single character: print the reading for the given character to the stdout stream.
  For a character list: for each of the listed characters, print the character and
  its reading separated by a single tab character to the stdout stream.

Options:
  -q, --quiet       suppress error messages from the stderr stream
  -s, --source={CKMOUV}
                    a single character must be provided, out of C,K,M,O,U,V;
                    return the reading for the specified system, the options are:
                    C -> Cantonese
                    K -> Korean
                    M -> Mandarin
                    O -> Japanese On
                    U -> Japanese Kun
                    V -> Vietnamese
                    the default value for this option is 'M'

  -h, --help        show this help message and exit"

readonly SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
readonly IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"
readonly READINGS_FILE="$SOURCE_DIR/../Unihan/Unihan_Readings.txt"

QUIET=false
SOURCE_LETTER='M'

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-$progName -o qs:h -l "quiet,source:,help" -- "$@")

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
            SOURCE_LETTER="$2"; shift 2 ;;
        -h | --help )
            echo "$helpText"; exit 0 ;;
        -- )
            shift; break ;;
        * )
            break ;;
    esac
done

# Process the source option letter
if [[ ${#SOURCE_LETTER} -gt 1 ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: only one argument may be given for the option 's|source'" >&2
        echo "$helpHint" >&2
    fi
    exit 2
elif [[ -n $(echo $SOURCE_LETTER | sed 's/[CKMOUV]//gI') ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: invalid argument for the option 's|source'" >&2
        echo "$helpHint" >&2
    fi
    exit 2
else
    case $SOURCE_LETTER in
        c | C )
            SOURCE_KEY='kCantonese' ;;
        k | K )
            SOURCE_KEY='kKorean' ;;
        m | M )
            SOURCE_KEY='kMandarin' ;;
        o | O )
            SOURCE_KEY='kJapaneseOn' ;;
        u | U )
            SOURCE_KEY='kJapaneseKun' ;;
        v | V )
            SOURCE_KEY='kVietnamese' ;;
    esac
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

# Deal with an invalid IDS database file
if [[ ! -e $IDS_FILE ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: IDS database file not found, aborting" >&2
    fi
    exit 3
fi
# Deal with an invalid Readings file
if [[ ! -e $READINGS_FILE ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: Unihan Readings file not found, aborting" >&2
    fi
    exit 3
fi

get_character_reading () {
    local givenChar=$1

    # Only accept one character at a time
    [ ${#givenChar} != 1 ] && return 1

    # Check if the given character is present in the
    # IDS database, and if so, get its unicode number
    local charUnicode
    charUnicode=$(grep -P "\t$givenChar\t" "$IDS_FILE" | sed "s/\t.*//")
    [[ -z $charUnicode ]] && return 2

    # Check if the given character is present in the Readings database
    local charReading
    charReading=$(grep "$charUnicode.$SOURCE_KEY" "$READINGS_FILE")
    [[ -z $charReading ]] && return 3

    # Extract the pinyin reading and return it
    local charPinyin
    charPinyin=$(echo "$charReading" | sed "s/.*\t//")
    echo "$charPinyin"
    return 0
}

reading=$(get_character_reading "$INPUT")
exitCode=$?
if [[ $exitCode == 0 ]]; then
    echo "$reading"
elif [[ $QUIET == false ]]; then
    case $exitCode in
        2)
            echo "The given character is not present in the database." >&2 ;;
        3)
            echo "The given character has no reading information for the selected source." >&2 ;;
    esac
fi
exit $exitCode
