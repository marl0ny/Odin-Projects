package wavepacket

import "core:math"
import "../gl_wrappers"
import "../gl_wrappers/quads"

@(private="file")
Programs::struct {
    is_initialized: b32,
    wavepacket: gl_wrappers.glsl_program
}

s_programs: Programs = {is_initialized=false}

@(private="file")
init_programs::proc() {
    if !s_programs.is_initialized {
        s_programs.wavepacket \
            = quads.make_program(
                "./shaders/wavepacket/init.frag")
    }
}

init_wave_packet_gl::proc(psi: quads.Quad, wf: WavePacket) {
    using gl_wrappers
    init_programs()
    quads.draw(
        psi, s_programs.wavepacket,
        {
            "amplitude"=wf.a,
            "sigmaX"=wf.sx, "sigmaY"=wf.sy,
            "r0"=Vec2 {wf.x0, wf.y0},
            "wavenumber"=IVec2 {i32(wf.nx), i32(wf.ny)}
        }
    )
}