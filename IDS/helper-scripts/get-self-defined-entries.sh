#! /bin/sh

IDS_FILE='../IDS.TXT'

# Get the lines of the characters whose
# composition is the character itself
selfDefinedChars=$(sed -n "/^[^\t]*\t\(.\)\t^\1/p" "$IDS_FILE")

# Remove everything before the character
selfDefinedChars=$(echo "$selfDefinedChars" | sed "s/^[^\t]*\t//")
# Remove everything after the caracter
selfDefinedChars=$(echo "$selfDefinedChars" | sed -r "s/^(.).*/\1/")

echo "$selfDefinedChars"
