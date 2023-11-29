#include "decode_no_io.h"

struct png_file {
  unsigned char *buf;
  unsigned int size;
  unsigned int cur;
};

typedef struct png_file png_file;

void user_read_fn(png_structp png, png_bytep out, png_size_t len) {
  png_voidp io_ptr = png_get_io_ptr(png);
  if (io_ptr == NULL) {
    return;
  }

  png_file *f = (png_file*) io_ptr;
  // bounds check
  if (len < f->size && f->cur+len < f->size) {
    memcpy(out, f->buf+f->cur, len);
  }

  f->cur += len;
}

int png_decode(unsigned char* data, unsigned int size, unsigned char*** row_pointers, size_t* height, size_t* row_bytes) {
  png_file user_io_ptr = {
    .buf = data,
    .size = size,
    .cur = 0,
  };

  png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  png_infop info = png_create_info_struct(png);

  png_set_read_fn(png, &user_io_ptr, user_read_fn);
  png_read_info(png, info);
  
  *height = png_get_image_height(png, info);
  png_byte color_type = png_get_color_type(png, info);
  png_byte bit_depth = png_get_bit_depth(png, info);
  
  if (bit_depth == 16)
    png_set_strip_16(png);
  
  if (color_type == PNG_COLOR_TYPE_PALETTE) 
    png_set_palette_to_rgb(png);
  /* PNG_COLOR_TYPE_GRAY_ALPHA is always 8 or 16bit depth. */
  if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) 
    png_set_expand_gray_1_2_4_to_8(png);
  if (png_get_valid(png, info, PNG_INFO_tRNS)) 
    png_set_tRNS_to_alpha(png);
  /* These color_type don't have an alpha channel then fill it with 0xff. */
  if (color_type == PNG_COLOR_TYPE_RGB || color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_PALETTE) 
    png_set_filler(png, 0xFF, PNG_FILLER_AFTER);
  else if (color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_GRAY_ALPHA) 
    png_set_gray_to_rgb(png);
  
  png_read_update_info(png, info);
  
  *row_bytes = png_get_rowbytes(png,info);

  *row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * (*height));
  for (int y = 0; y < *height; y++) {
    (*row_pointers)[y] = (png_byte*) malloc(*row_bytes);
  }

  // Does the actual decoding
  png_read_image(png, *row_pointers);
  
  png_destroy_read_struct(&png, &info, NULL);
  return 0;
}
