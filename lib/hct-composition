#! /bin/sh

if [[ -z $1 ]]; then
    echo "No file provided." >&2
    exit 1
elif [[ ! -f $1 ]]; then
    echo "The provided file does not exist." >&2
    exit 1
fi
INPUT="$1"

function get_character_composition {
    local givenChar=$1

    # Only accept one character at a time
    [ ${#givenChar} != 1 ] && return 1

    # Curl the wiktionary page for the given character
    local url="https://en.wiktionary.org/wiki/$givenChar"
    local html
    html=$(curl -# -L "${url}" 2> '/dev/null')

    # Check if the page has a 'Han character' section and the
    # corresponding line where the character composition should be
    local hanCharacterHeadword
    hanCharacterHeadword=$(echo "$html" | grep -m 1 -A 15 '<div class="mw-heading mw-heading3"><h3 id="Han_character">Han character</h3>')
    hanCharacterHeadword=$(echo "$hanCharacterHeadword" | grep '<span class="headword-line"><strong class="Hani headword" lang="mul">')
    [[ -z $hanCharacterHeadword ]] && return 2

    # Check if there is composition information present
    local compositionString
    compositionString=$(echo "$hanCharacterHeadword" | grep 'composition')
    compositionString=$(echo "$compositionString" | sed 's/.*composition//')
    [[ -z $compositionString ]] && return 3

    # Extract the composition string for the character
    # Remove the html tags
    compositionString=$(echo "$compositionString" | sed 's/<[^>]*>//g')
    # Remove the first blankspace
    compositionString=$(echo "$compositionString" | sed 's/^ //')
    # Remove the last solitary parenthesis
    compositionString=$(echo "$compositionString" | sed 's/)$//')

    echo "$compositionString"
    return 0
}

lineCount=$(sed -n '$=' "$INPUT")
processCount=0
while read testedChar; do
    ((processCount++))
    echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
    composition=$(get_character_composition "$testedChar")
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
