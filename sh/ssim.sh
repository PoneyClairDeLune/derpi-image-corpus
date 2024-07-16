#!/bin/bash
ssimBin="$(ls ssim/bin/linux-*gcc*/release/rmgr-ssim)"
testChannel=''
case "$1" in
	"y")
		testChannel='y'
		;;
	"r")
		testChannel='0'
		;;
	"g")
		testChannel='1'
		;;
	"b")
		testChannel='2'
		;;
	*)
		echo "Invalid channel value. Should be 0 (R), 1 (G), 2 (B) or y (luminance)." >&2
		exit 1
		;;
esac
if [ ! -f "${2}" ]; then
	echo "The provided source image does not exist." >&2
	exit 1
fi
if [ ! -f "${3}" ]; then
	echo "The provided target image does not exist." >&2
	exit 1
fi
if [ ! -f "${3}.png" ]; then
	#if [[ "${3}" == *".jxl" ]]; then
	#	djxl --quiet "${3}" "${3}.png"
	#elif [[ "${3}" == *".webp" ]]; then
	#	dwebp -quiet "${3}" -o "${3}.png"
	#elif [[ "${3}" == *".jpg" ]]; then
	#	djpeg -outfile "${3}.png" "${3}"
	#elif [[ "${3}" == *".avif" ]]; then
	#	avifdec "${3}" "${3}.png" > /dev/null
	#else
		#echo "Extension not matched!" >&2
		vips copy "${3}" "${3}.png[compression=3]"
	#fi
fi
"$ssimBin" -${testChannel} "${2}" "${3}.png"
exit