#!/bin/bash
set -e

help() {
	echo "Run hyperfine tests for decoding algorithm with WASM target. Assume"
  echo "that decode.c -> decode.aot transformation has already occured."
	echo 
	echo "Syntax: bash wasm_test.sh [-h|s]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    Run tests on SIMD-enabled AOT compiler."
	echo
}

while getopts "hs" OPTION
do
	case $OPTION in
		h) help
				exit;;
		s) simd=true
				echo "simd enabled...";;
	esac
done

if [[ "$simd" = true ]]; then
	cp /dev/null wasm_with_sse.csv
	for i in {0..250}
	do
		/opt/wasm-micro-runtime/product-mini/platforms/linux/build/iwasm \
		--dir=/home/jgoldman/image_decoding decode_simd.aot \
		/home/jgoldman/image_decoding/large.png \
		/home/jgoldman/image_decoding/wasm_with_simd.csv
	done
	python3 stat_analysis.py wasm_with_simd.csv

else
	cp /dev/null wasm_no_simd.csv
	for i in {0..250}
	do
		/opt/wasm-micro-runtime/product-mini/platforms/linux/build/iwasm \
		--dir=/home/jgoldman/image_decoding decode_nosimd.aot \
		/home/jgoldman/image_decoding/large.png \
		/home/jgoldman/image_decoding/wasm_no_simd.csv
	done
	python3 stat_analysis.py wasm_no_simd.csv
fi