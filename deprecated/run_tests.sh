#!/bin/bash
set -e

help() {
	echo "Run benchmark test"
	echo 
	echo "Syntax: bash build.sh [-h|s|w]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    sse enabled"
	echo "w    built to wasm"
	echo
}

while getopts "hsw" OPTION
do
	case $OPTION in
		h) help
				exit;;
		s) sse=true
				echo "sse enabled...";;
		w) wasm=true
				echo "wasm compilation enabled...";;
	esac
done

if [[ "$sse" = true && "$wasm" = true ]]; then # SSE and WASM
echo "CONSIDER WASM CASE"
elif [[ "$sse" = true ]]; then # SSE and no WASM
  # Compile
  gcc -I/usr/local/include/libpng16 -I/opt/simde-no-tests/wasm \
	-L/usr/local/lib -o decode decode.c -lpng16
  # Run tests
	hyperfine -w 20 -r 100 './decode large.png' --export-json with_sse.json --show-output
  # Export graph
	python3 /opt/hyperfine/scripts/plot_histogram.py with_sse.json -o with_sse.png \
  --title "Native Execution Speed With SSE2" \
  --t-min 0.25 \
  --t-max 0.4
elif [[ "$wasm" = true ]]; then # no SSE and WASM
echo "CONSIDER WASM CASE"
else # no SSE and no WASM
  # Compile
  gcc -I/usr/local/include/libpng16 -I/opt/simde-no-tests/wasm \
  -L/usr/local/lib -o decode decode.c -lpng16
  # Run tests
	hyperfine -w 20 -r 100 './decode large.png' --export-json no_sse.json
  # Export graph
	python3 /opt/hyperfine/scripts/plot_histogram.py no_sse.json -o no_sse.png \
  --title "Native Execution Speed Without SSE2" \
  --t-min 0.25 \
  --t-max 0.4
fi