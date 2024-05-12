package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"
import "complex"
import "fft"
import bmp "bitmap"
import color "domain_coloring"
import wp "wavepacket"
import "window"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"
import "quads"

N : u32 : 1024
psi := [N*N]complex.Complex {}
energies := [N*N]f32 {}
potential := [N*N]f32 {}
image_data: = [3*N*N]u8 {}


glfw_implementation::proc() {
	using complex

	window_width: i32 = 1024
	window_height: i32 = 1024
	window := window.init_window(window_width, window_height)
	// window_width2, window_height2 : = glfw.GetFramebufferSize(window)

	// The below line is necessary in order to avoid a segmentation
	// fault. See GingerBill's gist:
	// https://gist.github.com/gingerBill/b03c2ea6ed693034a609e56076fda3dc
	gl.load_up_to(3, 2, glfw.gl_set_proc_address)

	view_program := quads.make_program("./shaders/domain_coloring/view.frag")
	copy_program := quads.make_program("./shaders/util/copy.frag")
	wavepacket_program: \
		= quads.make_program("./shaders/wavepacket/init.frag")
	target_tex_params: quads.TextureParams = {}
	target_quad := quads.new(target_tex_params)
	tex_params2: quads.TextureParams = {
		format=gl.RG32F,
		width=i32(N), height=i32(N),
		generate_mipmap=true,
		wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
		min_filter=gl.LINEAR, mag_filter=gl.LINEAR
	}
	psi0 := quads.new(tex_params2)
	psi1 := quads.new(tex_params2)

	init_potential_norm_coords(
		.DOUBLE_SLIT,
		potential[0: N*N], w=N, h=N,
		a=1.0,
		x0=0.44, y0=0.4, x1=0.56, y1=0.42, s=0.02
	)
	tex_params3: quads.TextureParams = {
		format=gl.R32F,
		width=i32(N), height=i32(N),
		generate_mipmap=true,
		wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
		min_filter=gl.LINEAR, mag_filter=gl.LINEAR
	}
	phi := quads.new(tex_params3)
	quads.substitute_array(phi, &potential[0])

	gl.Viewport(0, 0, i32(N), i32(N))
	{
		wp.init_wave_packet_gl(psi0, 
			{a=10.0, x0=0.5, y0=0.2, sx=0.05, sy=0.05, nx=0.0, ny=40.0})
	}

	for {

		gl.Viewport(0, 0, i32(N), i32(N))
		{
			split_step(psi1, psi0, phi, 
						{dt=Complex{0.8, 0.0}, m=1.0, hbar=1.0,
						 nx=i32(N), ny=i32(N)})
			quads.swap(&psi0, &psi1)

		}

		gl.Viewport(0, 0, window_width, window_height)
		{
			quads.draw(
				target_quad, view_program, {"tex"=psi0}
			)
		}
		
		glfw.PollEvents()
		if glfw.WindowShouldClose(window) {
			break
		}
		glfw.SwapBuffers(window)
	}
	glfw.DestroyWindow(window)
	glfw.Terminate()
}

pure_cpu_bmp_output_implementation::proc() {
	using complex;

	energy_free_periodic(energies[0: N*N], N, N,
					     // mass=1.0, c=137.026, 
						 // pde_type=.KLEIN_GORDON
						)
	wp.init_wave_packet_norm_coords(
		psi[0: N*N], w=N, h=N, 
		wf={60.0, 0.5, 0.25, 0.05, 0.05, 0.0, 50.0})
	// init_potential_norm_coords(
	// 	.HARMONIC_OSCILLATOR,
	// 	potential[0: N*N], w=N, h=N, 
	// 	a=30.0
	// )
	init_potential_norm_coords(
		.DOUBLE_SLIT,
		potential[0: N*N], w=N, h=N,
		a=10.0,
		x0=0.43, y0=0.4, x1=0.57, y1=0.42, s=0.05
	)

	image_count := 0
	time_step:f32 = 0.25
	for i in 0..<400 {
		// fmt.printf("Step number: %d\n", i)
		propogate_spatial(psi[0: N*N], potential[0: N*N],
						  w=N, h=N, t=0.5*time_step)
		fft.parallel_square_fft(psi[0: N*N], n=N,
								th_total=4, is_inverse=false)
		propagate_kinetic(psi[0: N*N], energies[0: N*N],
						  w=N, h=N, t=time_step)
		fft.parallel_square_fft(psi[0: N*N], n=N, 
								th_total=4, is_inverse=true)
		propogate_spatial(psi[0: N*N], potential[0: N*N],
						  w=N, h=N, t=0.5*time_step)
		
		if (i%3 == 0) {
			color.complex_array_to_color_bytes(image_data[0: 3*N*N],
										    	psi[0: N*N], w=N, h=N)
			info := bmp.get_default_bitmap_header(N, N)

			// string builder wasn't in the demo file
			// and I don't think it was in the documentation;
			// had to look at the Odin source code
			// to find it.
			str_builder := strings.builder_make()
			if (image_count < 10) {
				strings.write_string(&str_builder, "image00")
			} else if (image_count < 100) {
				strings.write_string(&str_builder, "image0")
			} else if (image_count < 1000) {
				strings.write_string(&str_builder, "image")
			}
			strings.write_int(&str_builder, image_count)
			strings.write_string(&str_builder, ".bmp")
			filename: string = strings.to_string(str_builder)
			fmt.printf("Saving %s\n", filename)
			bmp.write_bitmap(filename, &info, image_data[0:3*N*N])
			image_count += 1
		}
	}
}

main :: proc() {
	if len(os.args) >= 2 {
		if os.args[1] == "bmp" || os.args[1] == "--bmp" {
			pure_cpu_bmp_output_implementation()
		} else if os.args[1] == "glfw" || os.args[1] == "--glfw" {
			glfw_implementation()	
		}
	} else {
		glfw_implementation()
	}
}
