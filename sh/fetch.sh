#!/bin/bash
if [ "$1" == "" ]; then
	echo "No corpus provided. A list is available below."
	cd corpus
	ls -1 *.tsv | while IFS= read -r line; do
		echo "    · ${line/\.tsv/}"
	done
elif [ -f "./corpus/${1}.tsv" ]; then
	mkdir -p tmp
	cd tmp
	mkdir -p "$1"
	cd "$1"
	rm -fv ./*
	cat "../../corpus/${1}.tsv" | while IFS= read -r line; do
		if [ "$(echo $line | cut -d' ' -f1)" != "id" ]; then
			#id="$(echo $line | cut -d' ' -f1)"
			url="$(echo $line | cut -d' ' -f3)"
			echo "Fetching from \"${url}\""
			curl -LOJ "${url}"
		fi
	done
	echo "Download finished."
else
	echo "No valid corpus provided."
fi
exit
