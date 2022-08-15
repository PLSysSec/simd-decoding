#!/usr/bin/python3
import numpy as np
import sys
import matplotlib.pyplot as plt
import config

def get_improvement(hi, lo, performance):
  """
  Get improvement from two execution speeds.
  Arguments:
    hi, lo: (double) execution speeds
    performance: (bool) True if calculating performance increase, False if calculating time reduction.
  Returns: (double) Calculated improvement
  """
  if (lo > hi):
    print('input order incorrect')
    sys.exit()
  return 100 * (hi - lo) / (lo if performance else hi)

def generate_data():
  data = {}
  config.init()
  for filename in config.file_struct.keys():
    raw_data = np.genfromtxt(filename,delimiter=',')
    data[filename] = (np.mean(raw_data), raw_data)
  return data


def generate_txt(data):
  """
  Generate output .txt file
  Arguments:
    data = {filename: (average execution time, [raw data])}
  """
  native_comp_p = get_improvement(data[config.native_no_sse_fn][0], data[config.native_sse_fn][0], True)
  wasm_comp_p = get_improvement(data[config.wasm_no_simd_fn][0], data[config.wasm_simd_fn][0], True)
  simd_comp_p = get_improvement(data[config.wasm_simd_fn][0], data[config.native_sse_fn][0], True)
  no_simd_comp_p = get_improvement(data[config.wasm_no_simd_fn][0], data[config.native_no_sse_fn][0], True)

  native_comp_t = get_improvement(data[config.native_no_sse_fn][0], data[config.native_sse_fn][0], False)
  wasm_comp_t = get_improvement(data[config.wasm_no_simd_fn][0], data[config.wasm_simd_fn][0], False)
  simd_comp_t = get_improvement(data[config.wasm_simd_fn][0], data[config.native_sse_fn][0], False)
  no_simd_comp_t = get_improvement(data[config.wasm_no_simd_fn][0], data[config.native_no_sse_fn][0], False)

  with open(config.comp_struct[0], 'w') as f:
    f.write("averages: \n")
    f.write("  native without sse2  : " + str(data[config.native_no_sse_fn][0]) + "\n")
    f.write("  native with sse2     : " + str(data[config.native_sse_fn][0]) + "\n")
    f.write("  wasm without simd128 : " + str(data[config.wasm_no_simd_fn][0]) + "\n")
    f.write("  wasm with simd128    : " + str(data[config.wasm_simd_fn][0]) + "\n")
    f.write("\n")
    f.write("performance increase percentage [100 * (hi - lo) / lo]: \n")
    f.write("  native without sse2 -> native with sse2     : " + str(native_comp_p) + "\n")
    f.write("  wasm without simd128 -> wasm with simd128   : " + str(wasm_comp_p) + "\n")
    f.write("  wasm with simd128 -> native with sse2       : " + str(simd_comp_p) + "\n")
    f.write("  wasm without simd128 -> native without sse2 : " + str(no_simd_comp_p) + "\n")
    f.write("\n")
    f.write("time reduction percentage [100 * (hi - lo) / hi]: \n")
    f.write("  native without sse2 -> native with sse2     : " + str(native_comp_t) + "\n")
    f.write("  wasm without simd128 -> wasm with simd128   : " + str(wasm_comp_t) + "\n")
    f.write("  wasm with simd128 -> native with sse2       : " + str(simd_comp_t) + "\n")
    f.write("  wasm without simd128 -> native without sse2 : " + str(no_simd_comp_t) + "\n")


def generate_plt(data):
  """
  Generate output histogram .png file
  Arguments:
    data = {filename: (average execution time, [raw data])}
  """
  bins = np.arange(config.MIN, config.MAX, 0.01)
  plt.hist(data[config.native_no_sse_fn][1], bins, alpha=0.5, label=config.comp_struct[1][0], edgecolor="black")
  plt.hist(data[config.native_sse_fn][1], bins, alpha=0.5, label=config.comp_struct[1][1], edgecolor="black")
  plt.hist(data[config.wasm_no_simd_fn][1], bins, alpha=0.5, label=config.comp_struct[1][2], edgecolor="black")
  plt.hist(data[config.wasm_simd_fn][1], bins, alpha=0.5, label=config.comp_struct[1][3], edgecolor="black")
  
  plt.xlabel("Time [s]")
  plt.ylabel("Frequency")
  plt.legend(loc='upper left', fontsize='small')
  plt.title(config.comp_struct[2])
  plt.savefig(config.comp_struct[3])  


def generate_bar(data):
  """
  Generate output bar chart .png file
  Arguments:
    data = {filename: (average execution time, [raw data])}
  """
  x_axis = config.comp_struct[5]
  y_axis = np.zeros(4)
  for i in range(4):
    y_axis[i + 1 if i % 2 == 0 else i - 1] = list(data.values())[i][0]
  print(x_axis)
  print(y_axis)
  plt.figure(figsize=(6,6))
  plt.bar(x_axis, y_axis)
  plt.xlabel('Implementation')
  plt.ylabel('Time [s]')
  plt.title(config.comp_struct[2])
  plt.savefig(config.comp_struct[4])
    

def main():
  data = generate_data()
  generate_txt(data)
  generate_plt(data)
  plt.close()
  generate_bar(data)


if __name__ == "__main__":
  main()