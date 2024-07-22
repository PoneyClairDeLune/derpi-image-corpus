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
	echo "id	cat	testId	size" > "../../data/${1}.lossy.size.tsv"
	echo "id	cat	testId	ssim" > "../../data/${1}.lossy.ssim.tsv"
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
			# WebP 56dB
			echo "Saving WebP PSNR 56dB at $(date "+%T")..."
			cwebp -mt -psnr 56 -qrange 90 99 -m 5 -o "test.${id}.p56.webp" 2> /dev/null "$file"
			# WebP q95
			echo "Saving WebP q95 at $(date "+%T")..."
			cwebp -mt -q 95 -m 5 -o "test.${id}.q95.webp" "$file" 2> /dev/null
			# JXL d1.0 p
			echo "Saving JPEG XL d1.0 at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 1 -p --progressive_dc 1 "$file" "test.${id}.d1.jxl" 2> /dev/null
			# JXL d2.0 p
			echo "Saving JPEG XL d2.0 at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 2 -p --progressive_dc 1 "$file" "test.${id}.d2.jxl" 2> /dev/null
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
			# AVIF q90
			echo "Saving AVIF q90 at $(date "+%T")..."
			vips copy "${file}" "test.${id}.q90.avif[compression=av1,lossless=false,Q=90]"
			# WebP near lossless (fake lossless)
			echo "Saving WebP fake lossless at $(date "+%T")..."
			cwebp -mt -near_lossless 60 -m 6 -o "test.${id}.nl.webp" "$file" 2> /dev/null
			# JXL near lossless (fake lossless)
			echo "Saving JPEG XL fake lossless at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -m 1 -d 0.1 -e 7 "$file" "test.${id}.nl.jxl" 2> /dev/null
			# Collecting reports...
			echo "Collecting reports at $(date "+%T")..."
			echo "${id}	${category}	source	$(wc -c ${file} | cut -d' ' -f1)" >> "../../data/${1}.lossy.size.tsv"
			ls -1 "test.${id}."* | while IFS= read -r testfile; do
				# Size
				export fid="${id}"
				export tfn="${testfile}"
				echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	\$(wc -c ${testfile} | cut -d' ' -f1)\"" | bash >> "../../data/${1}.lossy.size.tsv"
				echo "Collecting SSIM metrics at $(date "+%T")..."
				echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	$(../../shx ssim tmp/${1}/${file} tmp/${1}/${testfile})\"" | bash >> "../../data/${1}.lossy.ssim.tsv"
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
