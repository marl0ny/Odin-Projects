/* Implementation of the split operator method.

References:

Split-Operator Method:
James Schloss. The Split Operator Method - Arcane Algorithm Archive.
https://www.algorithm-archive.org/contents/split-operator_method/
 split-operator_method.html
*/
package main

import "core:math"
import "complex"

PDEType :: enum {
	SCHRODINGER, KLEIN_GORDON
}

energy_free_periodic::proc(
	energy: []f32, w: u32, h: u32,
	mass: f32 = 1.0, c: f32 = 137.036, pde_type: PDEType = .SCHRODINGER) {
	for i in 0..<h {
		for j in 0..<w {
			i_, j_: i32 = i32(i), i32(j)
			i_shift: i32 = i_ if i_ < i32(w)/2 else -i32(w) + i_
			j_shift: i32 = j_ if j_ < i32(h)/2 else -i32(h) + j_
			px: f32 = 2.0*math.PI*f32(i_shift)/f32(w)
			py: f32 = 2.0*math.PI*f32(j_shift)/f32(h)
			p2: f32 = px*px + py*py
			switch(pde_type) {
				case .KLEIN_GORDON:
					m2, c2, c4: f32 = mass*mass, c*c, c*c*c*c
					energy[i*w + j] = math.sqrt(p2*c2 + m2*c4)
				case .SCHRODINGER:
					energy[i*w + j] = p2/(2.0*mass)
			}
		}
	}
}

propagate_kinetic::proc(psi_p: []complex.Complex, energies: []f32,
						w:u32, h: u32,
						t: f32, hbar: f32 = 1.0) {
	for i in 0..<h {
		for j in 0..<w {
			energy: f32 = energies[i*w + j]
			psi_p[i*w + j] = complex.mul(
				{math.cos(energy*t/hbar), -math.sin(energy*t/hbar)},
				psi_p[i*w + j]
			) 
		}
	}
}


// propagate_spatial_4vector::proc(psi: []complex.Complex,
// 							    potential: []Potential,
// 						        w: u32, h: u32, t: f32, hbar: f32 = 1.0) {
// 	for i in 0..<h {
// 		for j in 0..<w {
// 			vec_potential: f32 = potential[i*w + j]
// 			psi_p[i*w + j] = complex.mul(
// 				{math.cos(energy*t/hbar), -math.sin(energy*t/hbar)},
// 				psi_p[i*w + j]
// 			)
// 		}
// 	}
// }

propagate_spatial_scalar::proc(psi: []complex.Complex, potential: []f32,
	                           w: u32, h: u32, t: f32, hbar: f32 = 1.0) {
	for i in 0..<h {
		for j in 0..<w {
			phi: f32 = potential[i*w + j]
			psi[i*w + j] = complex.mul(
				{math.cos(phi*t/hbar), -math.sin(phi*t/hbar)}, psi[i*w + j]
			)
		}
	}
}

propogate_spatial::proc { // propagate_spatial_4vector, 
						 propagate_spatial_scalar}
