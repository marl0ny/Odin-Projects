/* This file creates and controls the GLSL FFT programs.

References:

Wikipedia - Cooley–Tukey FFT algorithm
https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm

MathWorld Wolfram - Fast Fourier Transform:
http://mathworld.wolfram.com/FastFourierTransform.html 

William Press et al.
12.2 Fast Fourier Transform (FFT) - Numerical Recipes
https://websites.pmc.ucsc.edu/~fnimmo/eart290c_17/NumericalRecipesinF77.pdf

*/
package fft

import "core:math"
import "core:fmt"
import "../gl_wrappers/quads"
import "../gl_wrappers"
import gl "vendor:OpenGL"

@private
Programs::struct {
    is_initialized: b32,
    fft_iter: gl_wrappers.glsl_program,
    rev_bit_sort2: gl_wrappers.glsl_program,
    fftshift: gl_wrappers.glsl_program,
    copy: gl_wrappers.glsl_program
}

@private
s_programs := Programs {
    is_initialized=false
}

@(private="file")
CosTable::struct {
    use: b32,
    ind: [1024]f32,
    quad: quads.Quad,
    len: u32,
}

@(private="file")
s_cos_table := CosTable {use=false, len=0}


@(private="file")
modify_cos_arr::proc(n: u32) {
    if n != u32(s_cos_table.len) && n/2 <= 1024 {
        s_cos_table.len = n
        s_cos_table.ind[0] = 1.0
        s_cos_table.ind[n/8] = INVSQRT2
        s_cos_table.ind[n/4] = 0.0
        s_cos_table.ind[(3*n)/8] = -INVSQRT2
        for i in 1..<n/8 {
            c := math.cos(f32(i)*2.0*PI/f32(n))
            s := math.sin(f32(i)*2.0*PI/f32(n))
            s_cos_table.ind[i] = c
            s_cos_table.ind[n/4 - i] = s
            s_cos_table.ind[n/4 + i] = -s
            s_cos_table.ind[n/2 - i] = -c
        }
        viewport := [4]i32 {}
        gl.GetIntegerv(gl.VIEWPORT, &viewport[0])
        gl.Viewport(0, 0, i32(n/2), 1)
        {
            if s_cos_table.quad.id != 0 {
                quads.recycle(&s_cos_table.quad)
            }
            s_cos_table.quad = quads.new({
                format=gl.R32F, width=i32(n/2), height=1,
                generate_mipmap=true,
                wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
                min_filter=gl.LINEAR,
                mag_filter=gl.LINEAR})
            quads.substitute_array(s_cos_table.quad,
                                   &s_cos_table.ind[0])
        }
        gl.Viewport(viewport[0], viewport[1],
                    viewport[2], viewport[3])

    }
}

@(private="file")
init::proc() {
    if !s_programs.is_initialized {
        s_programs.is_initialized = true
        s_programs.fft_iter \
            = quads.make_program("./shaders/fft/fft-iter.frag")
        s_programs.fftshift \
            = quads.make_program("./shaders/fft/fftshift.frag")
        s_programs.rev_bit_sort2 = quads.make_program(
            "./shaders/fft/rev-bit-sort2.frag")
        s_programs.copy = quads.make_program(
            "./shaders/util/copy.frag")
    }
}

@private
fft_iter2d::proc(iter_quads_param: [2]^quads.Quad,
                 is_vertical: b32,
                 is_inverse: b32) -> [2]^quads.Quad {
    using quads
    iter_quads := [2]^quads.Quad {iter_quads_param[0],
                                  iter_quads_param[1]}
    width: u32 = u32(iter_quads[0].params.width)
    height: u32 = u32(iter_quads[0].params.height)
    // glViewport(0, 0, width, height)
    size: u32 = height if is_vertical else width
    modify_cos_arr(size)
    iter_count: u32 = 0
    for block_size: u32 = 2; block_size <= size; block_size *= 2 {
        quads.draw(
            iter_quads[1]^,
            s_programs.fft_iter,
            {
                "tex"=iter_quads[0]^,
                "isVertical"=i32(is_vertical),
                "blockSize"=f32(block_size)/f32(size),
                "angleSign"=f32(1.0) if is_inverse else f32(-1.0),
                "scale"=1.0/f32(size) if is_inverse && block_size == size \
                     else f32(1.0),
                "size"=f32(size),
                "useCosTable"=true,
                "cosTableTex"=s_cos_table.quad,
            }
        )
        tmp: ^quads.Quad = iter_quads[0]
        iter_quads[0] = iter_quads[1]
        iter_quads[1] = tmp
    }
    return iter_quads
}

@private
rev_bit_sort2::proc(dst: quads.Quad, src: quads.Quad) {
    width := dst.params.width
    height := dst.params.height
    quads.draw(
        dst, s_programs.rev_bit_sort2,
        {"tex"=src, "width"=width, "height"=height}
    )
}


fft2d::proc(dst: quads.Quad, src: quads.Quad) {
    init()
    width := dst.params.width
    height := dst.params.height
    tex_params: gl_wrappers.TextureParams = {
        format=gl.RGBA32F,
        width=i32(width), height=i32(height),
        generate_mipmap=true,
        wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
        min_filter=gl.LINEAR, mag_filter=gl.LINEAR
    }
    iter_quad1, iter_quad2 := quads.new(tex_params), quads.new(tex_params)
    defer {
        quads.recycle(&iter_quad1)
        quads.recycle(&iter_quad2)
    }
    rev_bit_sort2(iter_quad1, src)
    iter_quads1 := [2]^quads.Quad {&iter_quad1, &iter_quad2}
    iter_quads2 := fft_iter2d(iter_quads1,
                              is_vertical=false, is_inverse=false)
    iter_quads3 := fft_iter2d(iter_quads2,
                              is_vertical=true, is_inverse=false)
    quads.draw(dst, s_programs.copy, {"tex"=iter_quads3[0]^})
}


ifft2d::proc(dst: quads.Quad, src: quads.Quad) {
    init()
    width := dst.params.width
    height := dst.params.height
    tex_params: gl_wrappers.TextureParams = {
        format=gl.RGBA32F,
        width=i32(width), height=i32(height),
        generate_mipmap=true,
        wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
        min_filter=gl.LINEAR, mag_filter=gl.LINEAR
    }
    iter_quad1, iter_quad2 := quads.new(tex_params), quads.new(tex_params)
    defer {
        quads.recycle(&iter_quad1)
        quads.recycle(&iter_quad2)
    }
    rev_bit_sort2(iter_quad1, src)
    iter_quads1 := [2]^quads.Quad {&iter_quad1, &iter_quad2}
    iter_quads2 := fft_iter2d(iter_quads1,
                              is_vertical=false, is_inverse=true)
    iter_quads3 := fft_iter2d(iter_quads2,
                              is_vertical=true, is_inverse=true)
    quads.draw(dst, s_programs.copy, {"tex"=iter_quads3[0]^})
}
