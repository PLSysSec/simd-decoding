#!/bin/bash
set -e

help() {
	echo "Run benchmark test immediately after build.sh"
	echo 
	echo "Syntax: bash native_test.sh [-h|s|w]"
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

if [[ "$sse" = true ]]; then 
  cp /dev/null with_sse.csv
  gcc -I/usr/local/include/libpng16 -I/opt/simde-no-tests/wasm \
  -L/usr/local/lib -o decode decode.c -lpng16
  for i in {0..250}
  do
    ./decode large.png with_sse.csv
  done
  python3 stat_analysis.py with_sse.csv
else 
  cp /dev/null no_sse.csv
  gcc -I/usr/local/include/libpng16 -I/opt/simde-no-tests/wasm \
  -L/usr/local/lib -o decode decode.c -lpng16
  for i in {0..250}
  do
    ./decode large.png no_sse.csv
  done
  python3 stat_analysis.py no_sse.csv
fi
