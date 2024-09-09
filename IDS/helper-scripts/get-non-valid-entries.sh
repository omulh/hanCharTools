#! /bin/sh

# Make a temporary copy of the IDS database
TEMP_FILE=$(date +'tmp_%H%M%S')
IDS_FILE='../IDS.TXT'
cp "$IDS_FILE" "./$TEMP_FILE"

# Remove comment lines
sed -i '/#/d' "./$TEMP_FILE"

# Remove the notes present in some lines
sed -i "s/\t\*.*//" "./$TEMP_FILE"

# Remove everything before the entry's character
sed -i "s/^[^\t]*\t//" "./$TEMP_FILE"

# Remove composition options with subtraction IDCs,
# i.e., compositions with ㇯ in them
while [[ -n $(sed -n "/\t[^\t]*㇯[^\t]*\t/p" "./$TEMP_FILE") ]]; do
    sed -i "s/\t[^\t]*㇯[^\t]*\t/\t"/ "./$TEMP_FILE"
done
sed -i "s/^[^\t]*㇯[^\t]*\t//" "./$TEMP_FILE"
sed -i "s/\t[^\t]*㇯[^\t]*$//" "./$TEMP_FILE"
sed -i "s/^[^\t]*㇯[^\t]*$//" "./$TEMP_FILE"

# Remove composition options with unencoded
# components, i.e. compositions with {} in them
while [[ -n $(sed -n "/\t[^\t]*[{}][^\t]*\t/p" "./$TEMP_FILE") ]]; do
    sed -i "s/\t[^\t]*[{}][^\t]*\t/\t"/ "./$TEMP_FILE"
done
sed -i "s/^[^\t]*[{}][^\t]*\t//" "./$TEMP_FILE"
sed -i "s/\t[^\t]*[{}][^\t]*$//" "./$TEMP_FILE"
sed -i "s/^[^\t]*[{}][^\t]*$//" "./$TEMP_FILE"

# Remove composition options with unrepresentable
# components, i.e. compositions with ？ in them
while [[ -n $(sed -n "/\t[^\t]*？[^\t]*\t/p" "./$TEMP_FILE") ]]; do
    sed -i "s/\t[^\t]*？[^\t]*\t/\t"/ "./$TEMP_FILE"
done
sed -i "s/^[^\t]*？[^\t]*\t//" "./$TEMP_FILE"
sed -i "s/\t[^\t]*？[^\t]*$//" "./$TEMP_FILE"
sed -i "s/^[^\t]*？[^\t]*$//" "./$TEMP_FILE"

# Return the characters that are left withou any composition option after the removal
grep -P "^.$" "./$TEMP_FILE"

rm "./$TEMP_FILE"
