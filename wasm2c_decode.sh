#!/bin/bash
set -e

help() {
	echo "Configure decode.c and WAMR compiler with libpng WASM target."
	echo 
	echo "Syntax: bash wasm_decode.sh [-h|s]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    Run with WASM SIMD128 instructions enabled for libpng library"
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

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")