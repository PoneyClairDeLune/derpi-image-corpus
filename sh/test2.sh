#!/bin/bash
if [ "$1" == "" ]; then
	echo "No corpus provided. A list is available below."
	cd corpus
	ls -1 *.tsv | while IFS= read -r line; do
		echo "    · ${line/\.tsv/}"
	done
elif [ -d "./tmp/${1}" ]; then
	mkdir -p ./data
	cd "tmp/$1"
	rm test.* 2>/dev/null
	echo "id	cat	testId	size" > "../../data/${1}.lossless.size.tsv"
	#echo "id	cat	testId	ssim" > "../../data/${1}.lossless.ssim.tsv"
	lineCount=$(($(wc -l "../../corpus/${1}.tsv" | cut -d' ' -f1)-1))
	lineNow=0
	cat "../../corpus/${1}.tsv" | while IFS= read -r line; do
		if [ "$(echo $line | cut -d' ' -f1)" != "id" ]; then
			let lineNow=lineNow+1
			id="$(echo $line | cut -d' ' -f1)"
			category="$(echo $line | cut -d' ' -f2)"
			#url="$(echo $line | cut -d' ' -f3)"
			file="$(ls -1 ${id}.* | grep -E "${id}\.(png|jpg)")"
			echo -e "\033[1;37mNew progress\033[0m: Working on \"$file\" at $(date "+%T")... (${lineNow}/${lineCount})"
			# WebP lossless
			echo "Saving WebP lossless at $(date "+%T")..."
			cwebp -mt -lossless -m 6 -o "test.${id}.d0.webp" "$file" 2> /dev/null
			# JXL lossless
			echo "Saving JPEG XL lossless at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 0 -e 7 "$file" "test.${id}.d0.jxl" 2> /dev/null
			# JXL lossless
			echo "Saving JPEG XL lossless progressive at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 0 -e 7 -p "$file" "test.${id}.d0p.jxl" 2> /dev/null
			# AVIF lossless
			echo "Saving AVIF lossless at $(date "+%T")..."
			vips copy "${file}" "test.${id}.d0.avif[compression=av1,lossless=true]"
			# Collecting reports...
			echo "Collecting reports at $(date "+%T")..."
			echo "${id}	${category}	source	$(wc -c ${file} | cut -d' ' -f1)" >> "../../data/${1}.lossless.size.tsv"
			ls -1 "test.${id}."* | while IFS= read -r testfile; do
				# Size
				export fid="${id}"
				export tfn="${testfile}"
				echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	\$(wc -c ${testfile} | cut -d' ' -f1)\"" | bash >> "../../data/${1}.lossless.size.tsv"
				#echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}.y	$(../../shx ssim y tmp/${1}/${file} tmp/${1}/${testfile})\"" | bash >> "../../data/${1}.lossless.ssim.tsv"
			done
			echo "Cleaning up for the next round $(date "+%T")..."
			rm "test.${id}."*
		fi
	done
	echo "Test finished."
else
	echo "No valid corpus provided."
fi
exit
