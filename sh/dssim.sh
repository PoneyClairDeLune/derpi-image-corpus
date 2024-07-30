#!/bin/bash
sourceFile="${1}"
targetFile="${2}"
if [ "$USEDIR" != "" ]; then
	sourceFile="${INVOKE_DIR}/${1}"
	targetFile="${INVOKE_DIR}/${2}"
fi
if [ ! -f "${sourceFile}" ]; then
	echo "The provided source image does not exist." >&2
	exit 1
fi
if [ ! -f "${targetFile}" ]; then
	echo "The provided target image does not exist." >&2
	exit 1
fi
if [ ! -f "${targetFile}.tmp.png" ]; then
	vips copy "${targetFile}" "${targetFile}.tmp.png[compression=3]"
fi
runBin="run/dssim"
if [ ! -f "$runBin" ]; then
	runBin="dssim"
fi
$runBin "${sourceFile}" "${targetFile}.tmp.png" | cut -d'	' -f1
exit
