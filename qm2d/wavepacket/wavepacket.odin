package wavepacket

import "core:math"
import "../complex"

WavePacket ::struct {
	a: f32,
	x0, y0: f32,
	sx, sy: f32,
	nx, ny: f32,
}

init_wave_packet_norm_coords::proc(
	arr: []complex.Complex, w: u32, h: u32, wf: WavePacket) {
	for i in 0..<h {
		for j in 0..<w {
			x: f32 = f32(j)/f32(w)
			y: f32 = f32(i)/f32(h)
			xt: f32 = x - wf.x0
			yt: f32 = y - wf.y0
			abs_val := wf.a*math.exp(-0.5*xt*xt/(wf.sx*wf.sx)) \
					       *math.exp(-0.5*yt*yt/(wf.sy*wf.sy))
			nr: f32 = wf.nx*x + wf.ny*y
			arr[i*w + j].x = abs_val*math.cos(2.0*math.PI*nr)
			arr[i*w + j].y = abs_val*math.sin(2.0*math.PI*nr)
		}
	}
}
