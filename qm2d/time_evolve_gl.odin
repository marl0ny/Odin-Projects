/* This file contains procedures for creating ang controlling
those GLSL programs who implement the split operator method.

References:

Split-Operator Method:
James Schloss. The Split Operator Method - Arcane Algorithm Archive.
https://www.algorithm-archive.org/contents/split-operator_method/\
split-operator_method.html
*/
package main

import "core:math"
import "gl_wrappers"
import "gl_wrappers/quads"
import "fft"


@(private="file")
Programs::struct {
    is_initialized: b32,
    splitstep_momentum: gl_wrappers.glsl_program,
    splitstep_spatial: gl_wrappers.glsl_program,
}

@(private="file")
s_programs: Programs = {}

@(private="file")
init_programs::proc () {
    if !s_programs.is_initialized {
        s_programs.splitstep_momentum \
            = quads.make_program(
                "./shaders/schrodinger/splitstep-momentum.frag")
        s_programs.splitstep_spatial \
            = quads.make_program(
                "./shaders/schrodinger/splitstep-spatial.frag")
    }
    s_programs.is_initialized = true
}

SimParams::struct {
    dt: complex64,
    m: f32,
    hbar: f32,
    nx: i32,
    ny: i32,
}

split_step::proc(psi1: quads.Quad, 
                 psi0: quads.Quad, 
                 phi: quads.Quad, sim_params: SimParams) {
    using gl_wrappers
    init_programs()
    dt: complex64 = sim_params.dt
    m, hbar :f32 = sim_params.m, sim_params.hbar
    nx, ny: i32 = sim_params.nx, sim_params.ny
    quads.draw(
        psi1, s_programs.splitstep_spatial,
        {"dt"=Vec2(transmute([2]f32)(dt/2.0)), "m"=m, "hbar"=hbar,
         "potentialTex"=phi,
         "psiTex"=psi0}
    )
    fft.fft2d(psi0, psi1)
    quads.draw(
        psi1, s_programs.splitstep_momentum,
        {"numberOfDimensions"=2,
         "texelDimensions2D"=IVec2{nx, ny},
         "dimensions2D"=Vec2{f32(nx), f32(ny)},
         "dt"=Vec2(transmute([2]f32)dt),
         "m"=m, "hbar"=hbar,
         "psiTex"=psi0}
    )
    fft.ifft2d(psi0, psi1)
    quads.draw(
        psi1, s_programs.splitstep_spatial,
        {"dt"=Vec2(transmute([2]f32)(dt/2.0)), "m"=m, "hbar"=hbar,
         "potentialTex"=phi,
         "psiTex"=psi0}
    )
}


