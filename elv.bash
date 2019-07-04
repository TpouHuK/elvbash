#!/bin/bash
# (not) Simple bash elv extracter
#
# (Dangerous, use only on trusted archives)

clc(){
	if [[ "$?" -ne "0" ]]
	then
		echo "PANIC!"
		exit 1
	fi
}

exec 3<$1
clc

read -u 3 -r -N 3 magic
clc

if [ "$magic" != "elv" ]
then
	echo "Invalid file format"
	exit 1
fi

while true
do

name_len=$(echo "obase=10; ibase=16; $(dd bs=1 count=4 2>/dev/null <&3 | od -t x1 -An | tr -dc '[:alnum:]' | tr '[:lower:]' '[:upper:]' | fold -w2 | tac | tr -d "\n")" | bc )
clc
if [[ "$name_len" -eq "0" ]]
then
	echo "Done"
	exit 0
fi

name="$(dd bs=1 count="$name_len" <&3 2>/dev/null)"
clc
content_len=$(echo "obase=10; ibase=16; $(dd bs=1 count=8 2>/dev/null <&3 | od -t x1 -An | tr -dc '[:alnum:]' | tr '[:lower:]' '[:upper:]' | fold -w2 | tac | tr -d "\n")" | bc)
clc

if [[ "$name" == "//"* ]]
then
	dd of=/dev/null bs=1 count="$content_len" 2>/dev/null <&3
	continue
fi

printf "Extracting %q... \t $content_len \n" "$name"

dir="$(dirname "$name")"

if [[ -n "$dir" ]]
then
	mkdir -p "$(dirname "$name")"
	clc
fi


if [ -f "$name" ]
then
	echo "Tried to overwrite file"
	echo "Aborting"
	exit 1
else
	# dd of="$name" bs=1 count="$content_len" 2>/dev/null <&3
	# dd of=/dev/null bs=1 count="$content_len" 2>/dev/null <&3
	# dd of=/dev/null bs="$content_len" count=1 2>/dev/null <&3

	dd of="$name" bs="$content_len" count=1 2>/dev/null <&3
	clc
fi

done
exec 3>&-
