/* Procedures for creating bitmap files.

Reference:

Wikipedia - BMP file format
https://en.wikipedia.org/wiki/BMP_file_format

 */
package bitmap

import "core:os"
import "core:fmt"

// This is not properly sized and packed as a proper bitmap image header 
// without adding the #packed directive. For example, without that directive
// padding is added in between M and total_file_size member.
BitmapHeader:: struct #packed {
    B: u8, // Must be set to 'B'
    M: u8, // Must be set to 'M'
    total_file_size: i32,  // In number of bytes
    reserved: [4]u8,
    data_offset: i32,  // Number of bytes offset to image data
    header_size: u32,  // In number of bytes
    width: i32, // Image dimensions
    height: i32,
    plane_count: u16, // Set to 1
    bits_per_pixel: u16,
    compression_method: u32, // Set to 0 for no compression
    image_size: u32, // Image data size in number of bytes
    horizontal_resolution: i32, // Horizontal dpi
    vertical_resolution: i32, // Vertical dpi
    color_palette_count: u32, // Set this to 16777216 colors
    important_colors_count: u32, // Set this to 0
}

get_default_bitmap_header::proc(width: u32, height: u32) -> BitmapHeader {
    return {
		B='B', M='M',
		total_file_size=54 + 3*i32(width)*i32(height),
		data_offset=54,
		header_size=40,
		width=i32(width), height=i32(height),
		plane_count=1,
		bits_per_pixel=24,
		compression_method=0,
		image_size=u32(3*width*height),
		horizontal_resolution=100,
		vertical_resolution=100,
		color_palette_count=16777216,
		important_colors_count=0,
	}
}


write_bitmap::proc(filename: string,
                   info: ^BitmapHeader, bytes: []u8) {
    perm : int = 0b0110110110
    // Made a mistake by using os.O_CREATE or some
    // other flag individually,
    // where the file didn't open properly as intended.
    // Must combine it with other flags.
    f, err0 := os.open(filename, os.O_CREATE | os.O_WRONLY, perm)
    if err0 != os.ERROR_NONE {
        fmt.println(err0)
    }
    c1, err1 := os.write_ptr(f, info, 54)
    c2, err2 := os.write_at(f, bytes, 54)
    if err1 != os.ERROR_NONE || err2 != os.ERROR_NONE {
        fmt.println(err1, err2)
    }
}
