package volume_render

import glw "../"
import "../quads"
import gl "vendor:OpenGL"
import "core:mem"

s_volume_render_programs := VolumeRenderPrograms {is_initialized=false}


@(private)
new_vertices::proc(
    render_texel_dimensions_2d: glw.IVec2,
    render_texel_dimensions_3d: glw.IVec3) -> [dynamic]glw.Vec2 {
    width: i32 = render_texel_dimensions_3d[0]
    height: i32 = render_texel_dimensions_3d[1]
    length: i32 = render_texel_dimensions_3d[2]
    number_of_vertices: i32 = length*6
    vertices := make([dynamic]glw.Vec2, number_of_vertices)
    /* for i in 0..<length {
        j := length - i - 1
        
    }*/
    return vertices;
}

@(private)
VolumeRenderQuads::struct {
    gradient: quads.Quad,
    vol_half_precision: quads.Quad,
    gradient_half_precision: quads.Quad,
    sample_volume: quads.Quad,
    sample_grad: quads.Quad,
    out: quads.Quad,
}

VolumeRender::struct {
    debug_rotation: quaternion128,
    sample_texel_dimensions_2d: glw.IVec2,
    render_texel_dimensions_2d: glw.IVec2,
    sample_texel_dimensions_3d: glw.IVec3,
    render_texel_dimensions_3d: glw.IVec3,
    view_dimensions: glw.IVec2,
    quad_data: VolumeRenderQuads,
}

@(private="file")
init_programs::proc() {
    s_volume_render_programs.gradient = quads.make_program(
        "./shaders/gradient/gradient3d.frag")
    s_volume_render_programs.sample_volume = quads.make_program(
        "./shaders/vol-render/sample.frag")
    s_volume_render_programs.show_volume = glw.program_from_paths(
        "./shaders/vol-render/display.vert", 
        "./shaders/vol-render/display.frag" 
    )
    s_volume_render_programs.sample_show_volume = glw.program_from_paths(
        "./shaders/vol-render/display.vert", 
        "./shaders/vol-render/sample-display.frag" 
    )
    s_volume_render_programs.is_initialized = true
}

@(private="file")
init_quads::proc(sample_texel_dimensions_2d: glw.IVec2, 
                 render_texel_dimensions_2d: glw.IVec2,
                 view_dimensions: glw.IVec2
                ) -> VolumeRenderQuads {

    tex_params_sample_f32 := glw.TextureParams {
        format=gl.RGBA32F,
        width=sample_texel_dimensions_2d.x,
        height=sample_texel_dimensions_2d.y,
        generate_mipmap=true,
        wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
        min_filter=gl.LINEAR, mag_filter=gl.LINEAR,
    }
    // gl.Viewport(0, 0, 
    //     sample_texel_dimensions_2d[0],
    //     sample_texel_dimensions_2d[1])
    // Main gradient frame

    // Create rgba16f quads for sampling
    tex_params_sample_f16 := glw.TextureParams {
        format=gl.RGBA16F,
        width=sample_texel_dimensions_2d[0],
        height=sample_texel_dimensions_2d[1],
        generate_mipmap=true,
        wrap_s=gl.REPEAT, wrap_t=gl.REPEAT,
        min_filter=gl.LINEAR, mag_filter=gl.LINEAR,
    }
    // gl.Viewport(0, 0, 
    //     sample_texel_dimensions_2d[0],
    //     sample_texel_dimensions_2d[1])
    // half precision volume and gradient frames

    // rgba16f quads for rendering
    tex_params_render_f16 := glw.TextureParams {
        format=gl.RGBA16F,
        width=render_texel_dimensions_2d[0],
        height=render_texel_dimensions_2d[1],
        generate_mipmap=true,
        wrap_s=gl.CLAMP_TO_EDGE, wrap_t=gl.CLAMP_TO_EDGE,
        min_filter=gl.LINEAR, mag_filter=gl.LINEAR,
    }
    // gl.Viewport(0, 0, 
    //     render_texel_dimensions_2d[0],
    //     render_texel_dimensions_2d[1])
    // sample volume and sample gradient frames

    // Construct vertices
    tex_params_view_f16 := glw.TextureParams {
        format=gl.RGBA16F, 
        width=view_dimensions[0],
        height=view_dimensions[1],
        generate_mipmap=true,
        wrap_s=gl.CLAMP_TO_EDGE, wrap_t=gl.CLAMP_TO_EDGE,
        min_filter=gl.LINEAR,
        mag_filter=gl.LINEAR,
    }

    return {
        gradient=quads.new(tex_params_sample_f16),
        vol_half_precision=quads.new(tex_params_sample_f16 ),
        gradient_half_precision=quads.new(tex_params_sample_f16),
        sample_volume=quads.new(tex_params_render_f16),
        sample_grad=quads.new(tex_params_render_f16),
        out=quads.new(tex_params_render_f16),
    }

}

@(private="file")
VolumeRenderPrograms::struct {
    is_initialized: b32,
    gradient: glw.glsl_program,
    sample_volume: glw.glsl_program,
    show_volume: glw.glsl_program,
    sample_show_volume: glw.glsl_program,
}
