#! /bin/sh

readonly progName='reading'
readonly progVersion=0.9
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the pronunciation (reading) of Han characters, aka Chinese characters, in different languages.

Input:
  A single input argument is accepted, and it must be one of the following:
  A single character, a file containing a list of single characters separated
  by newlines, or a '-' character to allow reading from the stdin stream.
  If the input argument is longer than one character, it is assumed to be a file.

Output:
  For a single character: print the reading for the given character to the stdout stream.
  For a character list: for each of the listed characters, print the character and
  its reading separated by a single tab character to the stdout stream.

Options:
  -d, --definition  get a brief definition for the given input instead of its pronunciation
  -q, --quiet       suppress error messages from the stderr stream
  -s, --source={CKMOUV}
                    a single character must be provided, out of [CKMOUV];
                    return the pronunciation for the specified language, the options are:
                    C -> Cantonese
                    K -> Korean
                    M -> Mandarin
                    O -> Japanese On
                    U -> Japanese Kun
                    V -> Vietnamese
                    the default value for this option is 'M'
                    this option is ignored when using the 'definition' option

  -V, --version     show version information and exit
  -h, --help        show this help message and exit"

readonly SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
readonly IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"
readonly READINGS_FILE="$SOURCE_DIR/../Unihan/Unihan_Readings.txt"

GET_DEFINITION=false
QUIET=false
SOURCE_LETTER='M'

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-$progName -o dqs:Vh -l "definition,quiet,source:,version,help" -- "$@")

# Deal with invalid command line arguments
if [ $? != 0 ]; then
    echo "$helpHint"
    exit 1
fi
eval set -- "$GIVEN_ARGS"

# Process the command line arguments
while true; do
    case "$1" in
        -d | --definition )
            GET_DEFINITION=true; shift ;;
        -q | --quiet )
            QUIET=true; shift ;;
        -s | --source )
            SOURCE_LETTER="$2"; shift 2 ;;
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

# Process the source option letter
if [[ ${#SOURCE_LETTER} -gt 1 ]]; then
    if [[ $QUIET == false ]]; then
        echo "htc-$progName: only one argument may be given for the option 's|source'" >&2
        echo "$helpHint" >&2
    fi
    exit 2
elif [[ -n $(echo "$SOURCE_LETTER" | sed 's/[CKMOUV]//gI') ]]; then
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
    [ ${#givenChar} != 1 ] && return 10

    # Check if the given character is present in the
    # IDS database, and if so, get its unicode number
    local charUnicode
    charUnicode=$(grep -P "\t$givenChar\t" "$IDS_FILE" | sed "s/\t.*//")
    [[ -z $charUnicode ]] && return 20

    # Check if the given character is present in the Readings database
    ! grep -q "^$charUnicode" "$READINGS_FILE" && return 21

    local charReading
    if [[ $GET_DEFINITION == false ]]; then
        charReading=$(grep "$charUnicode.$SOURCE_KEY" "$READINGS_FILE")
        [[ -z $charReading ]] && return 22
    else
        charReading=$(grep "$charUnicode.kDefinition" "$READINGS_FILE")
        [[ -z $charReading ]] && return 23
    fi

    # Extract the reading and return it
    charReading=$(echo "$charReading" | sed "s/.*\t//")
    echo "$charReading"
    return 0
}

# If input is a file
if [[ -e $INPUT ]]; then
    lineCount=$(sed -n '$=' "$INPUT")
    processCount=0
    if [ ! -t 1 ]; then
        echo "# Used options"
        if [[ $GET_DEFINITION == false ]]; then
            echo "# SOURCE_LETTER=$SOURCE_LETTER"
        else
            echo "# GET_DEFINITION=$GET_DEFINITION"
        fi
    fi
    while read testedChar; do
        ((processCount++))
        echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
        reading=$(get_character_reading "$testedChar")
        exitCode=$?
        if [ $exitCode == 0 ]; then
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$reading"
        else
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$exitCode"
        fi
    done < "$INPUT"
    echo -e "\r\033[0KProcessing done" >&2
    exit 0
# If input is a single character
elif [[ ${#INPUT} == 1 ]]; then
    reading=$(get_character_reading "$INPUT")
    exitCode=$?
    if [[ $exitCode == 0 ]]; then
        echo "$reading"
    elif [[ $QUIET == false ]]; then
        case $exitCode in
            20)
                echo "The given character is not present in the IDS database." >&2 ;;
            21)
                echo "The given character is not present in the Readings database." >&2 ;;
            22)
                echo "The given character has no reading information for the selected source." >&2 ;;
            23)
                echo "The given character has no definition information." >&2 ;;
        esac
    fi
    exit $exitCode
# If input has more than one character (and comes from stdin)
else
    lineCount=$(echo "$INPUT" | sed -n '$=')
    processCount=0
    if [ ! -t 1 ]; then
        echo "# Used options"
        if [[ $GET_DEFINITION == false ]]; then
            echo "# SOURCE_LETTER=$SOURCE_LETTER"
        else
            echo "# GET_DEFINITION=$GET_DEFINITION"
        fi
    fi
    while read testedChar; do
        ((processCount++))
        echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
        reading=$(get_character_reading "$testedChar")
        exitCode=$?
        if [ $exitCode == 0 ]; then
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$reading"
        else
            [ -t 1 ] && echo -en "\r\033[0K"
            echo -e "$testedChar\t$exitCode"
        fi
    done < <(echo "$INPUT")
    echo -e "\r\033[0KProcessing done" >&2
    exit 0
fi
