/* Complex struct. While complex numbers already form part of the core
language, I still made this to understand the basics of creating structs
in Odin. */
package complex

import "core:math"

@(private)
PI: f32: 3.141592653589793

Complex :: distinct [2]f32

mul::proc(x: Complex, y: Complex) -> Complex {
	return Complex {
		real(x)*real(y) - imag(x)*imag(y),
		real(x)*imag(y) + imag(x)*real(y),
	}
}

real::proc(z: Complex) -> f32 {
	return z.x;
}

imag::proc(z: Complex) -> f32 {
	return z.y;
}

conj::proc(z: Complex) -> Complex {
	return Complex {z.x, -z.y}
}

abs2::proc(z: Complex) -> f32 {
	return real(mul(conj(z), z))
}

arg::proc(z: Complex) -> f32 {
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


/* Complex::struct {
	real: f32,
	imag: f32
}

mul::proc(x: Complex, y: Complex) -> Complex {
	return Complex {
		x.real*y.real - x.imag*y.imag,
		x.real*y.imag + x.imag*y.real,
	}
}

arg::proc(z: Complex) -> f32 {
	if z.real == 0.0 {
		if z.imag >= 0.0 {
			return PI/2.0
		} else {
			return -PI/2.0
		}
	} else {
		val: f32 = math.atan(z.imag/z.real)
		if z.real < 0.0 {
			if z.imag >= 0.0 {
				return PI + val
			} else {
				return -PI + val
			}
		}
		return val
	}
}

add::proc(x: Complex, y: Complex) -> Complex {
	return Complex {
		x.real + y.real,
		x.imag + y.imag,
	}
}

sub::proc(x: Complex, y: Complex) -> Complex {
	return Complex {
		x.real - y.real,
		x.imag - y.imag,
	}
}

scale::proc(s: f32, z: Complex) -> Complex {
	return Complex {s*z.real, s*z.imag}
}*/
