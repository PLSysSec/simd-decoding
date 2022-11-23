#!/usr/bin/python3

def init():
  # minimum and maximum x-values for output graph
  global MIN, MAX
  MIN = 0.0
  MAX = 10.0

  # filenames
  global native_sse_fn, native_no_sse_fn, wasm2c_simd_fn, wasm2c_no_simd_fn
  native_sse_fn = 'results/native_with_sse.csv'
  native_no_sse_fn = 'results/native_no_sse.csv'
  #wasm_simd_fn = 'results/wasm_with_simd.csv'
  #wasm_no_simd_fn = 'results/wasm_no_simd.csv'
  wasm2c_simd_fn = 'results/wasm2c_with_simd.csv'
  wasm2c_no_simd_fn = 'results/wasm2c_no_simd.csv'

  # {filename : (.txt file for statistical results, histogram title, .png file for histogram)}
  global file_struct
  file_struct = {
    native_sse_fn: 
      ('results/native_with_sse_results.txt', 'Native Decoding with SSE2',      'results/native_with_sse.png'), 
    native_no_sse_fn: 
      ('results/native_no_sse_results.txt',   'Native Decoding without SSE2',   'results/native_no_sse.png'), 
    #wasm_simd_fn:   ('results/wasm_with_simd_results.txt',  'WASM Decoding with SIMD128',     'results/wasm_with_simd.png'), 
    #wasm_no_simd_fn:   ('results/wasm_no_simd_results.txt',    'WASM Decoding without SIMD128',  'results/wasm_no_simd.png'),
    wasm2c_simd_fn: 
      ('results/wasm2c_simd_results.txt',    'WASM2C Decoding with SIMD128',  'results/wasm2c_simd.png'),
    wasm2c_no_simd_fn: 
      ('results/wasm2c_no_simd_results.txt',    'WASM2C Decoding without SIMD128',  'results/wasm2c_no_simd.png'),
  }

  # output information for comp_analysis.py
  global comp_struct
  comp_struct = (
    'results/comparative_results.txt',     
    [
      'Native without SSE2',
      'Native with SSE2',
    #  'WASM without SIMD128',
    #  'WASM with SIMD128',
      'WASM2C without SIMD128',
      'WASM2C with SIMD128'
    ],
    'Comparison of Decoding Speeds',
    'results/comparison.png',
    'results/bar_chart.png',
    [
      'Native without\nSSE2',
      'Native with\nSSE2',
    #  'WASM without\nSIMD128',
    #  'WASM with\nSIMD128',
      'WASM2C without\nSIMD128',
      'WASM2C with\nSIMD128'
    ]
  )