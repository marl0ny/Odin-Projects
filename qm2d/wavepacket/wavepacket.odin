package wavepacket

import "core:math"
import "core:math/cmplx"


WavePacket ::struct {
	a: f32,
	x0, y0: f32,
	sx, sy: f32,
	nx, ny: f32,
}

init_wave_packet_norm_coords::proc(
	arr: []complex64, w: u32, h: u32, wf: WavePacket) {
	using cmplx
	for i in 0..<h {
		for j in 0..<w {
			x: f32 = f32(j)/f32(w)
			y: f32 = f32(i)/f32(h)
			xt: f32 = x - wf.x0
			yt: f32 = y - wf.y0
			abs_val := wf.a*math.exp(-0.5*xt*xt/(wf.sx*wf.sx)) \
					       *math.exp(-0.5*yt*yt/(wf.sy*wf.sy))
			nr: f32 = wf.nx*x + wf.ny*y
			arr[i*w + j] = complex64(abs_val)*exp(2.0i*complex64(math.PI*nr))
		}
	}
}
