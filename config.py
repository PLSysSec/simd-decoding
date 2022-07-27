#!/usr/bin/python3

def init():
  # minimum and maximum x-values for output graph
  global MIN, MAX
  MIN = 0.2
  MAX = 0.6

  # filenames
  global native_sse_fn, native_no_sse_fn, wasm_simd_fn, wasm_no_simd_fn
  native_sse_fn = 'native_with_sse.csv'
  native_no_sse_fn = 'native_no_sse.csv'
  wasm_simd_fn = 'wasm_with_simd.csv'
  wasm_no_simd_fn = 'wasm_no_simd.csv'

  # {filename : (.txt file for statistical results, histogram title, .png file for histogram)}
  global file_struct
  file_struct = {
    native_sse_fn: 
      ('native_with_sse_results.txt', 'Native Decoding with SSE2',      'native_with_sse.png'), 
    native_no_sse_fn: 
      ('native_no_sse_results.txt',   'Native Decoding without SSE2',   'native_no_sse.png'), 
    wasm_simd_fn: 
      ('wasm_with_simd_results.txt',  'WASM Decoding with SIMD128',     'wasm_with_simd.png'), 
    wasm_no_simd_fn: 
      ('wasm_no_simd_results.txt',    'WASM Decoding without SIMD128',  'wasm_no_simd.png') 
  }

  # output information for comp_analysis.py
  global comp_struct
  comp_struct = (
    'comparative_results.txt',     
    (
      'Native without SSE2',
      'Native with SSE2',
      'WASM without SIMD128',
      'WASM with SIMD128'
    ),
    'Comparison of Decoding Speeds',
    'comparison.png'
  )