#! /bin/sh

# Make a temporary copy of the IDS database
TEMP_FILE=$(date +'tmp_%H%M%S')
IDS_FILE='../IDS.TXT'
cp "$IDS_FILE" "./$TEMP_FILE"

# Use the copy to extract all the Chinese
# characters that are used in compositions
# for entries of the IDS database.
# Remove comment lines
sed -i '/#/d' "./$TEMP_FILE"
# Remove the notes present in some entries
sed -i "s/\t\*.*//" "./$TEMP_FILE"
# Remove the text before the first ^ character, i.e.,
# the unicode number and the entry's character
sed -i "s/^[^^]*\t^//" "./$TEMP_FILE"
# Remove some unwanted characters
sed -i 's/[A-Z0-9]//g' "./$TEMP_FILE"
sed -i 's/[][\t$^(){}]//g' "./$TEMP_FILE"
sed -i 's/[？〾⿰⿻⿱⿲⿳⿴⿵⿶⿷⿸⿹⿺⿿㇯⿾⿼⿽]//g' "./$TEMP_FILE"
# Arrange to one character per line
sed -i "s/./&\n/g" "./$TEMP_FILE"
sed -i '/^$/d' "./$TEMP_FILE"
# Remove duplicates
LC_ALL=C sort -u "./$TEMP_FILE" -o "./$TEMP_FILE"

# Check if the extracted chars have their
# own entry in the IDS database
lineCount=$(sed -n '$=' "./$TEMP_FILE")
processCount=0
while read testedChar; do
    ((processCount++))
    echo -ne "\r\033[0KProcessing line $processCount/$lineCount" >&2
    if ! grep -q -P "\t$testedChar\t" "$IDS_FILE"; then
        if [ -t 1 ]; then
            echo -e "\r\033[0K$testedChar"
        else
            echo "$testedChar"
        fi
    fi
done < "./$TEMP_FILE"
echo -e "\r\033[0KProcessing done" >&2

# Remove the temporary copy
rm "./$TEMP_FILE"
