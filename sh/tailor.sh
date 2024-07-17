#!/bin/bash
imgChannels=( 'y' )
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
	#echo "id	cat	testId	size" > "../../data/${1}.lossy.msize.tsv"
	#echo "id	cat	testId	ssim" > "../../data/${1}.lossy.mssim.tsv"
	lineCount=$(($(wc -l "../../corpus/${1}.tsv" | cut -d' ' -f1)-1))
	lineNow=0
	if [ "$(echo $line | cut -d' ' -f1)" != "id" ]; then
		let lineNow=lineNow+1
		id="$2"
		#url="$(echo $line | cut -d' ' -f3)"
		file="$(ls -1 ${id}.* | grep -E "${id}\.(png|jpg)")"
		echo -e "\033[1;37mNew progress\033[0m: Working on \"$file\" at $(date "+%T")... (${lineNow}/${lineCount})"
		# JXL progressive lossy
		echo "Saving JPEG XL at $(date "+%T")..."
		cjxl --num_threads -1 -j 0 -d 2 -p "$file" "test.${id}.jxl" 2> /dev/null
		# WebP lossy
		echo "Saving WebP at $(date "+%T")..."
		cwebp -mt -q 93 -m 6 -o "test.${id}.webp" "$file" 2> /dev/null
		# mozJPEG non-progressive
		echo "Saving mozJPEG at $(date "+%T")..."
		cjpeg -baseline -quality 80 -optimize -outfile "test.${id}.jpg" "$file" 2> /dev/null
		# mozJPEG progressive
		echo "Saving mozJPEG progressive at $(date "+%T")..."
		cjpeg -progressive -quality 80 -optimize -outfile "test.${id}.p.jpg" "$file" 2> /dev/null
		# AVIF
		echo "Saving AVIF at $(date "+%T")..."
		vips copy "${file}" "test.${id}.avif[compression=av1,lossless=false,Q=92]"
		echo "Assessing at $(date "+%T")..."
		ls -1 "test.${id}."* | while IFS= read -r testfile; do
			# Size
			echo "Size (${testfile/test.${id}./}): $(wc -c ${testfile} | cut -d' ' -f1) B"
		done
		ls -1 "test.${id}."* | while IFS= read -r testfile; do
			# Size
			echo "SSIM (${testfile/test.${id}./}): $(../../shx ssim y tmp/${1}/${file} tmp/${1}/${testfile})"
		done
		echo "Cleaning up for the next round $(date "+%T")..."
		rm *".tmp.png"
	fi
	echo "Test finished."
else
	echo "No valid corpus provided."
fi
exit
