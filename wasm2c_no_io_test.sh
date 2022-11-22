
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

N=20

echo "Build all the libraries"
#./build.sh 

echo "Build all the applications"
#./wasm2c_decode_no_io.sh 

###########################################
echo "Testing Native w/o SIMD"

# Clear out previous results
echo "" > results/native_no_sse.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_native images/large.png results/native_no_sse.csv
done

python3 stat_analysis.py results/native_no_sse.csv

###########################################
echo "Testing Native with SIMD"

# Clear out previous results
echo "" > results/native_with_sse.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_nativesimd images/large.png results/native_with_sse.csv
done

python3 stat_analysis.py results/native_with_sse.csv

###########################################
echo "Testing Wasm2c w/o SIMD"

# Clear out previous results
echo "" > results/wasm2c_no_simd.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_wasm images/large.png results/wasm2c_no_simd.csv
done

echo "[X] Analyzing WASMresults"
python3 stat_analysis.py results/wasm2c_no_simd.csv

###########################################
echo "Testing Wasm2c with SIMD"


# Clear out previous results
echo "" > results/wasm2c_with_simd.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/decode_wasmsimd images/large.png results/wasm2c_with_simd.csv
done

echo "[X] Analyzing WASMSIMD results"
python3 stat_analysis.py results/wasm2c_with_simd.csv

###########################################
echo "Done"
