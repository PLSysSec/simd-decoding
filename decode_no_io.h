#include <stdlib.h>
#include <string.h>
#include <png.h>

int png_decode(unsigned char* data, unsigned int size, unsigned char*** row_pointers, size_t* num_row_pointers, size_t* row_bytes);