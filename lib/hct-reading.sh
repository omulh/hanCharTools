#! /bin/sh

readonly progName='reading'
readonly progVersion=0.9
readonly helpHint="Try 'hct $progName --help' for more information."
readonly helpText="Usage: hct $progName [OPTION]... FILE|CHARACTER
Get the reading (pronunciation) of Han characters, aka Chinese characters, in different languages.

Input:
  A single input argument is accepted, and it must be one of the following:
  A single character, a file containing a list of single characters
  separated by newlines, or a '-' character to allow reading from stdin.
  If the input argument is longer than one character, it is assumed to be a file.

Output:
  For a single character: print the reading for the given character to stdout.
  For a character list: for each of the listed characters, print the character
  and its reading separated by a single tab character to stdout.

Options:
      --cantonese       return the Cantonese reading
      --japanese        return the Japanese reading
      --japanese-kun    return the Japanese Kun reading
      --japanese-on     return the Japanese On reading
      --korean          return the Korean reading
      --mandarin        return the Mandarin reading
      --vietnamese      return the Vietnamese reading
  -q, --quiet           suppress error messages from the stderr stream
  -V, --version     show version information and exit
  -h, --help        show this help message and exit

  If multiple language options are specified, only the last one given is considered.
  If no language option is specified, the Mandarin reading is returned."

readonly SOURCE_DIR=$(dirname -- "$(readlink -f "$0")")
readonly IDS_FILE="$SOURCE_DIR/../IDS/IDS.TXT"
readonly READINGS_FILE="$SOURCE_DIR/../Unihan/Unihan_Readings.txt"

QUIET=false
USED_LANGUAGE='mandarin'

# Parse the command line arguments
GIVEN_ARGS=$(getopt -n hct-$progName -o ''''''''''''qVh -l "cantonese,japanese,japanese-kun,japanese-on,korean,mandarin,vietnamese,quiet,version,help" -- "$@")

# Deal with invalid command line arguments
if [ $? != 0 ]; then
    echo "$helpHint"
    exit 1
fi
eval set -- "$GIVEN_ARGS"

# Process the command line arguments
while true; do
    case "$1" in
        --cantonese )
            USED_LANGUAGE='cantonese'; shift ;;
        --japanese )
            USED_LANGUAGE='japanese'; shift ;;
        --japanese-kun )
            USED_LANGUAGE='japanese-kun'; shift ;;
        --japanese-on )
            USED_LANGUAGE='japanese-on'; shift ;;
        --korean )
            USED_LANGUAGE='korean'; shift ;;
        --mandarin )
            USED_LANGUAGE='mandarin'; shift ;;
        --vietnamese )
            USED_LANGUAGE='vietnamese'; shift ;;
        -q | --quiet )
            QUIET=true; shift ;;
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

# Process the language option
case $USED_LANGUAGE in
    cantonese )
        LANG_KEY='kCantonese' ;;
    japanese )
        LANG_KEY='kJapanese' ;;
    japanese-on )
        LANG_KEY='kJapaneseOn' ;;
    japanese-kun )
        LANG_KEY='kJapaneseKun' ;;
    korean )
        LANG_KEY='kKorean' ;;
    mandarin )
        LANG_KEY='kMandarin' ;;
    vietnamese )
        LANG_KEY='kVietnamese' ;;
esac

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

    # Check if the given char has a reading for the selected language
    local charReading
    charReading=$(grep "$charUnicode\s$LANG_KEY\s" "$READINGS_FILE")
    [[ -z $charReading ]] && return 22

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
        echo "# USED_LANGUAGE=$USED_LANGUAGE"
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
                echo "The given character has no reading information for the selected language." >&2 ;;
        esac
    fi
    exit $exitCode
# If input has more than one character (and comes from stdin)
else
    lineCount=$(echo "$INPUT" | sed -n '$=')
    processCount=0
    if [ ! -t 1 ]; then
        echo "# Used options"
        echo "# USED_LANGUAGE=$USED_LANGUAGE"
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
