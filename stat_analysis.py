#!/usr/bin/python3
import numpy as np
import sys
import matplotlib.pyplot as plt
import config

def main(filename):
  config.init()
  data = np.genfromtxt(filename,delimiter=',')
  exports = config.file_struct[filename]
  
  with open(exports[0], 'w') as f:
    f.write("mean: " + str(np.mean(data)) + "\n")
    f.write("standard deviation: " + str(np.std(data)) + "\n")
    f.write("variance: " + str(np.var(data)) + "\n")
    f.write("max: " + str(max(data)) + "\n")
    f.write("min: " + str(min(data)) + "\n")

  _ = plt.hist(data, bins=25)
  plt.xlabel("Time [s]")
  plt.ylabel("Frequency")
  plt.title(exports[1])
  plt.xlim([config.MIN, config.MAX])

  plt.savefig(exports[2])

if __name__ == "__main__":
  main(sys.argv[1])