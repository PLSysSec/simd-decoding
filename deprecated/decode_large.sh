#!/bin/bash
gcc -I/usr/local/include/libpng16 -L/usr/local/lib -o decode decode.c -lpng16
hyperfine -w 20 -r 50 './decode large.png'
