#!/bin/bash
set -e

help() {
	echo "Run benchmark test after building libpng library"
    echo "Note: For WASM Target, wasm_decode.sh should be run before"
    echo "this to build the proper AOT compiler."
	echo 
	echo "Syntax: bash native_test.sh [-h|s|w]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    SIMD instructions included."
	echo "w    Built to WASM target."
	echo
}

while getopts "hsw" OPTION
do
	case $OPTION in
		h) help
				exit;;
		s) simd=true
				echo "simd enabled...";;
		w) wasm=true
				echo "wasm compilation enabled...";;
	esac
done

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

N=250

if [[ "$simd" = true && "$wasm" = true ]]; then # SIMD instructions and WASM target
  cp /dev/null wasm_with_simd.csv
	
  for i in {0..$N}
	do
		${WAMR_PATH}/product-mini/platforms/linux/build/iwasm \
		--dir=${SCRIPT_PATH} out/decode_simd.aot \
		${SCRIPT_PATH}/large.png \
		${SCRIPT_PATH}/wasm_with_simd.csv 
	done

	python3 stat_analysis.py wasm_with_simd.csv

elif [[ "$simd" = true ]]; then # SSE and native target
  cp /dev/null native_with_sse.csv

  gcc -I/usr/local/include/libpng16 -I${SIMDE_PATH}/wasm \
  -L/usr/local/lib -o out/decode decode_simd.c -lpng16

  for i in {0..$N}
  do
    out/decode large.png native_with_sse.csv
  done

  python3 stat_analysis.py native_with_sse.csv

elif [[ "$wasm" = true ]]; then # no SIMD and WASM target
	cp /dev/null wasm_no_simd.csv

	for i in {0..$N}
	do
		${WAMR_PATH}/product-mini/platforms/linux/build/iwasm \
		--dir=${SCRIPT_PATH} out/decode_nosimd.aot \
		${SCRIPT_PATH}/large.png \
		${SCRIPT_PATH}/wasm_no_simd.csv
	done

	python3 stat_analysis.py wasm_no_simd.csv

else # no SSE and native target
  cp /dev/null native_no_sse.csv

  gcc -I/usr/local/include/libpng16 \
  -L/usr/local/lib -o out/decode decode_no_simd.c -lpng16

  for i in {0..$N}
  do
    out/decode large.png native_no_sse.csv
  done
  python3 stat_analysis.py native_no_sse.csv

fi

echo "done"
