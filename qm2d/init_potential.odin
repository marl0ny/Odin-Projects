package main

import "core:math"

// Potential :: distinct [4]f32

PotentialType::enum {
	HARMONIC_OSCILLATOR, COULOMB, DOUBLE_SLIT, STEP
}

init_potential_norm_coords::proc(preset: PotentialType,
							     potential: []f32, w: u32, h: u32,
							     a: f32, 
								 x0: f32 = 0.5, y0: f32 = 0.5,
								 x1: f32 = 0.5, y1: f32 = 0.5,
								 s: f32 = 0.05) {
	for i in 0..<h {
		for j in 0..<w {
			x: f32 = f32(j)/f32(w)
			y: f32 = f32(i)/f32(h)
			r: f32 = math.sqrt((x-x0)*(x-x0) + (y-y0)*(y-y0))
			index := i*w + j
			switch(preset) {
				case .HARMONIC_OSCILLATOR:
					potential[index] = a*r*r
				case .COULOMB:
					potential[index] = a/r
				case .DOUBLE_SLIT:
					if y >= y0 && y < y1 {
						if (x < (x0 - 0.5*s)) || \
						    (x > (x0 + 0.5*s) && x < (x1 - 0.5*s)) ||\
						    (x > (x1 + 0.5*s)) {
							potential[index] = a
						}
					} else {
					    potential[index] = 0.0
                    }
				case .STEP:
					potential[index] = a if y > y0 else 0.0
			}
		}
	}
}
