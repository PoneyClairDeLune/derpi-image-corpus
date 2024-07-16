#!/bin/bash
magickCompare=''
useSsim=0
if [ -f "$(which magick)" ]; then
	magickCompare='magick compare'
elif [ -f "$(which compare)" ]; then
	magickCompare='compare'
else
	echo "ImageMagick is not present."
	exit 1
fi
if [ "$($magickCompare -list metric | grep 'SSIM')" != '' ]; then
	useSsim=1
fi
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
	echo "id	cat	testId	size" > "../../data/${1}.size.tsv"
	echo "id	cat	testId	psnr" > "../../data/${1}.psnr.tsv"
	echo "id	cat	testId	ssim" > "../../data/${1}.ssim.tsv"
	lineCount=$(wc -l "../../corpus/${1}.tsv")
	lineNow=1
	cat "../../corpus/${1}.tsv" | while IFS= read -r line; do
		if [ "$(echo $line | cut -d' ' -f1)" != "id" ]; then
			let lineNow=lineNow+1
			id="$(echo $line | cut -d' ' -f1)"
			category="$(echo $line | cut -d' ' -f2)"
			#url="$(echo $line | cut -d' ' -f3)"
			file="$(ls -1 ${id}.* | grep -E "${id}\.(png|jpg)")"
			echo -e "\033[1;37mNew progress\033[0m: Working on \"$file\" at $(date "+%T")... (${lineNow}/${lineCount})"
			# WebP lossless
			#echo "Saving WebP lossless at $(date "+%T")..."
			#cwebp -mt -lossless -m 6 -o "test.${id}.d0.webp" "$file" 2> /dev/null
			# WebP 56dB
			echo "Saving WebP PSNR 56dB at $(date "+%T")..."
			cwebp -mt -psnr 56 -qrange 90 99 -m 6 -o "test.${id}.p56.webp" 2> /dev/null "$file"
			# WebP q95
			echo "Saving WebP q95 at $(date "+%T")..."
			cwebp -mt -q 95 -m 6 -o "test.${id}.q95.webp" "$file" 2> /dev/null
			# JXL lossless
			echo "Saving JPEG XL lossless at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 0 "$file" "test.${id}.d0.jxl" 2> /dev/null
			# JXL d1.0 p
			echo "Saving JPEG XL d1.0 at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 1 -p "$file" "test.${id}.d1.jxl" 2> /dev/null
			# JXL d2.0 p
			echo "Saving JPEG XL d2.0 at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 2 -p "$file" "test.${id}.d2.jxl" 2> /dev/null
			# mozJPEG q95 np
			echo "Saving mozJPEG q95 at $(date "+%T")..."
			cjpeg -baseline -quality 95 -optimize -outfile "test.${id}.q95.jpg" "$file" 2> /dev/null
			# mozJXL q95 np
			echo "Saving mozJXL q95 at $(date "+%T")..."
			cjxl -j 1 "test.${id}.q95.jpg" "test.${id}.q95.jxl" 2> /dev/null
			# mozJPEG q95 p
			echo "Saving mozJPEG q95 progressive at $(date "+%T")..."
			cjpeg -progressive -quality 95 -optimize -outfile "test.${id}.q95p.jpg" "$file" 2> /dev/null
			# mozJXL q95 p
			echo "Saving mozJXL q95 progressive at $(date "+%T")..."
			cjxl -j 1 "test.${id}.q95p.jpg" "test.${id}.q95p.jxl" 2> /dev/null
			# AVIF lossless
			#echo "Saving AVIF lossless at $(date "+%T")..."
			#vips copy "${file}" "test.${id}.d0.avif[compression=av1,lossless=true]"
			# AVIF q95
			#echo "Saving AVIF q95 at $(date "+%T")..."
			#vips copy "${file}" "test.${id}.q95.avif[compression=av1,lossless=false,Q=95]"
			# Collecting reports...
			echo "Collecting reports at $(date "+%T")..."
			echo "${id}	${category}	source	$(wc -c ${file} | cut -d' ' -f1)" >> "../../data/${1}.size.tsv"
			ls -1 "test.${id}."* | while IFS= read -r testfile; do
				# Size
				export fid="${id}"
				export tfn="${testfile}"
				echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	\$(wc -c ${testfile} | cut -d' ' -f1)\"" | bash >> "../../data/${1}.size.tsv"
				echo "Collecting PSNR metrics at $(date "+%T")..."
				export psnr="$(${magickCompare} -metric PSNR "${file}" "${testfile}" "test.${id}.diff.png" 2>&1)"
				echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	${psnr}\"" | bash >> "../../data/${1}.psnr.tsv"
				if [ "$useSsim" != '0' ]; then
					echo "Collecting SSIM metrics at $(date "+%T")..."
					export ssim="$(${magickCompare} -metric SSIM "${file}" "${testfile}" "test.${id}.diff.png") 2>&1"
					echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	${ssim}\"" | bash >> "../../data/${1}.ssim.tsv"
				fi
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
