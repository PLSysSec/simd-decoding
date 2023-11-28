
if [ -z "$WASI_SDK_PATH" ]; then
	echo "Set WASI_SDK_PATH before running and run the following:"
	echo "  export PATH=\${WASI_SDK_PATH}/bin:\$PATH"
	echo "  export PATH=\${WASI_SDK_PATH}/bin/ranlib:\$PATH"
	exit 1
fi

if [ -z "$SIMDE_PATH" ]; then
	echo "Set SIMDE_PATH before running"
	exit 1
fi

if [ -z "$WASM2C_PATH" ]; then
	echo "Set WASM2C_PATH before running"
	exit 1
fi

PATH=${WASI_SDK_PATH}/bin:$PATH
PATH=${WASI_SDK_PATH}/bin/ranlib:$PATH

IMAGE=images/image.png
N=20
RESULTS_DIR=results


mkdir -p $RESULTS_DIR

echo "Build all the libraries"
#./build.sh

echo "Build all the applications"
#./wasm2c_decode_no_io.sh

###########################################
echo "Testing Native w/o SIMD"

# Clear out previous results
echo "" > $RESULTS_DIR/native_no_sse.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_native $IMAGE $RESULTS_DIR/native_no_sse.csv
done

echo "[X] Analyzing Native results"
python3 stat_analysis.py $RESULTS_DIR/native_no_sse.csv

###########################################
echo "Testing Native with SIMD"

# Clear out previous results
echo "" > $RESULTS_DIR/native_with_sse.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_nativesimd $IMAGE $RESULTS_DIR/native_with_sse.csv
done

echo "[X] Analyzing Native SIMD results"
python3 stat_analysis.py $RESULTS_DIR/native_with_sse.csv

###########################################
echo "Testing Wasm2c w/o SIMD"

# Clear out previous results
echo "" > $RESULTS_DIR/wasm2c_no_simd.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_wasm $IMAGE $RESULTS_DIR/wasm2c_no_simd.csv
done

echo "[X] Analyzing WASM results"
python3 stat_analysis.py $RESULTS_DIR/wasm2c_no_simd.csv

###########################################
echo "Testing Wasm2c with SIMD"


# Clear out previous results
echo "" > $RESULTS_DIR/wasm2c_with_simd.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_wasmsimd $IMAGE $RESULTS_DIR/wasm2c_with_simd.csv
done

echo "[X] Analyzing WASMSIMD results"
python3 stat_analysis.py $RESULTS_DIR/wasm2c_with_simd.csv

###########################################
echo "Done"
