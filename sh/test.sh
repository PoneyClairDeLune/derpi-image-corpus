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
	echo "id	cat	testId	ssimu2" > "../../data/${1}.lossy.ssim.tsv"
	echo "id	cat	testId	dssim" > "../../data/${1}.lossy.dssim.tsv"
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
			vips copy "${file}" "test.${id}.ppm"
			# WebP 56dB
			echo "Saving WebP PSNR 56dB at $(date "+%T")..."
			cwebp -mt -psnr 56 -qrange 90 99 -m 5 -o "test.${id}.p56.webp" 2> /dev/null "$file"
			# WebP q99
			echo "Saving WebP q99 at $(date "+%T")..."
			cwebp -mt -q 99 -m 5 -o "test.${id}.q99.webp" "test.${id}.ppm" 2> /dev/null
			# WebP q95
			echo "Saving WebP q95 at $(date "+%T")..."
			cwebp -mt -q 95 -m 5 -o "test.${id}.q95.webp" "test.${id}.ppm" 2> /dev/null
			# WebP q92
			echo "Saving WebP q92 at $(date "+%T")..."
			cwebp -mt -q 92 -m 5 -o "test.${id}.q92.webp" "test.${id}.ppm" 2> /dev/null
			# JXL d1.0 p
			echo "Saving JPEG XL d1.0 at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 1 -p --progressive_dc 1 "test.${id}.ppm" "test.${id}.d1.jxl" 2> /dev/null
			# JXL d2.0 p
			echo "Saving JPEG XL d2.0 at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -d 2 -p --progressive_dc 1 "test.${id}.ppm" "test.${id}.d2.jxl" 2> /dev/null
			# JXL HT
			echo "Saving JPEG XL HT at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -m 0 -d 0.25 -e 3 --faster_decoding 2 "test.${id}.ppm" "test.${id}.ht.jxl" 2> /dev/null
			# mozJPEG q95 np
			echo "Saving jpegli d1.0 at $(date "+%T")..."
			cjpegli -d 1.0 -p 0 "test.${id}.ppm" "test.${id}.q95.jpg" 2> /dev/null
			# mozJPEG q95 p
			echo "Saving jpegli d1.0 progressive at $(date "+%T")..."
			cjpegli -d 1.0 -p 2 "test.${id}.ppm" "test.${id}.q95p.jpg" 2> /dev/null
			# AVIF q90
			echo "Saving AVIF q90 at $(date "+%T")..."
			#vips copy "test.${id}.ppm" "test.${id}.q90.avif[compression=av1,lossless=false,Q=90]"
			# OpenJPEG J2K 85
			echo "Saving OpenJPEG J2K 85 at $(date "+%T")..."
			opj_compress -n 6 -I -SOP -EPH -mct 1 -p RPCL -b 64,64 -c "[256,256],[256,256],[128,128]" -t 512,512 -q 48 -i "${file}" -OutFor "JP2" -o "test.${id}.o85.jp2" > /dev/null 2> /dev/null
			# Grok J2K 85
			echo "Saving Grok J2K 85 at $(date "+%T")..."
			grk_compress -n 6 -I -S -E -u R -Y 1 -p RPCL -b 64,64 -c "[256,256],[256,256],[128,128]" -t 512,512 -q 45 -i "test.${id}.ppm" -O "JP2" -o "test.${id}.g85.jp2" 2> /dev/null
			# OpenJPH HTJ2K 85
			echo "Saving OpenJPH HTJ2K 85 at $(date "+%T")..."
			ojph_compress -tileparts R -reversible false -colour_trans true -prog_order RPCL -block_size "{64,64}" -precincts "{256,256},{256,256},{128,128}" -num_decomps 5 -i "test.${id}.ppm" -o "test.${id}.jph" >/dev/null 2>/dev/null
			ojph_expand -i "test.${id}.jph" -o "test.${id}.jph.ppm" 2>/dev/null
			#rm "test.${id}.jph"
			# Grok HTJ2K
			#echo "Saving Grok HTJ2K at $(date "+%T")..."
			#grk_compress -i "${file}" -O "JPH" -o "test.${id}.grok.jph"
			# WebP near lossless (fake lossless)
			echo "Saving WebP fake lossless at $(date "+%T")..."
			cwebp -mt -near_lossless 60 -m 6 -o "test.${id}.nl.webp" "test.${id}.ppm" 2> /dev/null
			# JXL smaller near lossless (fake lossless)
			echo "Saving JPEG XL smaller fake lossless at $(date "+%T")..."
			cjxl --num_threads -1 -j 0 -m 1 -d 0.2 -e 7 "test.${id}.ppm" "test.${id}.snl.jxl" 2> /dev/null
			rm "test.${id}.ppm"
			# Collecting reports...
			echo "Collecting reports at $(date "+%T")..."
			echo "${id}	${category}	source	$(wc -c ${file} | cut -d' ' -f1)" >> "../../data/${1}.lossy.size.tsv"
			ls -1 "test.${id}."* | while IFS= read -r testfile; do
				# Size
				export fid="${id}"
				#if [ "${testfile}" != *"..ppm" ]; then
					export tfn="${testfile}"
					echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	\$(wc -c ${testfile} | cut -d' ' -f1)\"" | bash >> "../../data/${1}.lossy.size.tsv"
					echo "Collecting SSIMULACRA2 metrics at $(date "+%T")..."
					echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	$(../../shx ssim tmp/${1}/${file} tmp/${1}/${testfile})\"" | bash >> "../../data/${1}.lossy.ssim.tsv"
					echo "Collecting DSSIM metrics at $(date "+%T")..."
					echo "echo \"\${fid}	${category}	\${tfn/test.${fid}./}	$(../../shx dssim tmp/${1}/${file} tmp/${1}/${testfile})\"" | bash >> "../../data/${1}.lossy.dssim.tsv"
				#fi
			done
			echo "Cleaning up for the next round $(date "+%T")..."
			rm "test.${id}."*
		fi
	done
	echo "Test finished."
	shx analyze $1
else
	echo "No valid corpus provided."
fi
exit
