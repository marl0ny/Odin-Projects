/* Procedures for domain colouring complex valued data.

References:

Wikipedia - Domain coloring
https://en.wikipedia.org/wiki/Domain_coloring

Wikipedia - Hue
https://en.wikipedia.org/wiki/Hue

https://en.wikipedia.org/wiki/Hue#/media/File:HSV-RGB-comparison.svg

 */
package color

import "core:math"
import "core:math/cmplx"

Color :: distinct [3]f32


@(private="file")
PI: f32: 3.141592653589793

@(private="file")
arg::proc(z: complex64) -> f32 {
	if real(z) == 0.0 {
		if imag(z) >= 0.0 {
			return PI/2.0
		} else {
			return -PI/2.0
		}
	} else {
		val: f32 = math.atan(imag(z)/real(z))
		if real(z) < 0.0 {
			if imag(z) >= 0.0 {
				return PI + val
			} else {
				return -PI + val
			}
		}
		return val
	}
}

argument_to_color::proc(arg_val: f32) -> Color {
    max_col: f32 = 1.0
    min_col: f32 = 50.0/255.0
    col_range: f32 = max_col - min_col
    if arg_val <= math.PI/3.0 && arg_val >= 0.0 {
        return Color {
            max_col,
            min_col + col_range*arg_val/(math.PI/3.0),
            min_col
        }
    } else if arg_val > math.PI/3.0 && arg_val <= 2.0*math.PI/3.0 {
        return Color {
            max_col - col_range*(arg_val - math.PI/3.0)/(math.PI/3.0),
            max_col,
            min_col
        }
    } else if arg_val > 2.0*math.PI/3.0 && arg_val <= math.PI {
        return Color {
            min_col,
            max_col,
            min_col + col_range*(arg_val - 2.0*math.PI/3.0)/(math.PI/3.0),
        }
    } else if arg_val < 0.0 && arg_val > -math.PI/3.0 {
        return Color {
            max_col,
            min_col,
            min_col - col_range*arg_val/(math.PI/3.0)
        }
    } else if arg_val <= -math.PI/3.0 && arg_val > -2.0*math.PI/3.0 {
        return Color {
            max_col + (col_range*(arg_val + math.PI/3.0)/(math.PI/3.0)),
            min_col,
            max_col
        }
    } else if arg_val <= -2.0*math.PI/3.0 && arg_val >= -math.PI {
        return Color {
            min_col,
            min_col - (col_range*(arg_val + 2.0*math.PI/3.0))/(math.PI/3.0),
            max_col
        }
    }
    return Color {min_col, max_col, max_col}
}

complex_array_to_color_bytes::proc(bytes: []u8, z: []complex64,
                                   w: u32, h: u32) {
    using cmplx
    for i in 0..< h {
        for j in 0..< w {
            z_ij := z[i*w + j]
            c := argument_to_color(arg(z_ij))
            abs_z2 := abs(z_ij)*abs(z_ij)
            // color := domain_coloring.Color {z_ij.x, 0, 0}
            bytes[3*(i*w + j)] = u8(min(255.0, abs_z2*c.b))
            bytes[3*(i*w + j) + 1] = u8(min(255.0, abs_z2*c.g))
            bytes[3*(i*w + j) + 2] = u8(min(255.0, abs_z2*c.r))
        }
    }
}