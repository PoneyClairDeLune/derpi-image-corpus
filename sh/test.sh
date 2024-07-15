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
	echo "id	testId	size" > "../../data/${1}.size.tsv"
	echo "id	testId	psnr" > "../../data/${1}.psnr.tsv"
	echo "id	testId	ssim" > "../../data/${1}.ssim.tsv"
	cat "../../corpus/${1}.tsv" | while IFS= read -r line; do
		if [ "$(echo $line | cut -d' ' -f1)" != "id" ]; then
			id="$(echo $line | cut -d' ' -f1)"
			#url="$(echo $line | cut -d' ' -f3)"
			file="$(ls -1 ${id}.* | grep -E "${id}\.(png|jpg)")"
			echo "Working on \"$file\"..."
			# WebP lossless
			cwebp -mt -lossless -m 6 -o "test.${id}.d0.webp" "$file"
			# WebP 56dB
			cwebp -mt -psnr 56 -qrange 90 99 -m 6 -o "test.${id}.p56.webp" "$file"
			# WebP q95
			cwebp -mt -q 95 -m 6 -o "test.${id}.q95.webp" "$file"
			# JXL lossless
			#cjxl --num_threads -1 -j 0 -d 0 "$file" "test.${id}.d0.jxl"
			# JXL d1.0 p
			cjxl --num_threads -1 -j 0 -d 1 -p "$file" "test.${id}.d1.jxl"
			# JXL d2.0 p
			cjxl --num_threads -1 -j 0 -d 2 -p "$file" "test.${id}.d2.jxl"
			# mozJPEG q95 np
			cjpeg -baseline -quality 95 -optimize -outfile "test.${id}.q95.jpg" "$file"
			# mozJXL q95 np
			cjxl -j 1 "test.${id}.q95.jpg" "test.${id}.q95.jxl"
			# mozJPEG q95 p
			cjpeg -progressive -quality 95 -optimize -outfile "test.${id}.q95p.jpg" "$file"
			# mozJXL q95 p
			cjxl -j 1 "test.${id}.q95p.jpg" "test.${id}.q95p.jxl"
			# AVIF lossless
			# AVIF q95
			# Collecting reports...
			echo "Collecting reports..."
			echo "${id}	source	$(wc -c ${file} | cut -d' ' -f1))" >> "../../data/${1}.size.tsv"
			ls -1 "test.${id}."* | while IFS= read -r testfile; do
				# Size
				export fid="${id}"
				export tfn="${testfile}"
				echo "echo \"\${fid}	\${tfn/test.${fid}./}	\$(wc -c ${testfile} | cut -d' ' -f1)\"" | bash >> "../../data/${1}.size.tsv"
			done
			echo "Cleaning up for the next round..."
			rm "test.${id}."*
		fi
	done
	echo "Test finished."
else
	echo "No valid corpus provided."
fi
exit
