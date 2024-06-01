package gl_wrappers

import "core:strings"
import "core:fmt"
import "core:os"

import gl "vendor:OpenGL"


Vec2 :: distinct [2]f32
Vec3 :: distinct [3]f32
Vec4 :: distinct [4]f32
IVec2 :: distinct [2]i32
IVec3 :: distinct [3]i32
IVec4 :: distinct [4]i32

glsl_program :: distinct u32

TextureParams::struct {
    format: i32,
    width: i32, height: i32,
    generate_mipmap: b32,
    wrap_s: i32, wrap_t: i32,
    min_filter: i32, mag_filter: i32
}

acquire_new_frame::proc() -> u32 {
    defer {
        s_frame_count += 1;
    }
    return s_frame_count;
}

to_base::proc(sized: i32) -> u32 {
    switch sized {
        case gl.RGBA32F, gl.RGBA32I, gl.RGBA32UI, gl.RGBA16F, \
        gl.RGBA16I, gl.RGBA16UI, gl.RGBA8I, gl.RGBA8UI, gl.RGBA8:
            return gl.RGBA
        case gl.RGB32F, gl.RGB32I, gl.RGB32UI, gl.RGB16F, \
        gl.RGB16I, gl.RGB16UI, gl.RGB8I, gl.RGB8UI, gl.RGB8:
            return gl.RGB
        case gl.RG32F, gl.RG32I, gl.RG32UI, gl.RG16F, \
        gl.RG16I, gl.RG16UI, gl.RG8I, gl.RG8UI:
            return gl.RG
        case gl.R32F, gl.R32I, gl.R32UI, gl.R16F, \
        gl.R16I, gl.R16UI, gl.R8, gl.R8UI:
            return gl.RED
    }
    return 0
}

to_type::proc(sized: i32) -> u32 {
    switch sized {
        case gl.RGBA32F, gl.RGB32F, gl.RG32F, gl.R32F:
            return gl.FLOAT
        case gl.RGBA32I, gl.RGB32I, gl.RG32I, gl.R32I:
            return gl.INT
        case gl.RGBA32UI, gl.RGB32UI, gl.RG32UI, gl.R32UI:
            return gl.UNSIGNED_INT
        case gl.RGBA16F, gl.RGB16F, gl.RG16F, gl.R16F:
            return gl.HALF_FLOAT
        case gl.RGBA16I, gl.RGB16I, gl.RG16I, gl.R16I:
            return gl.SHORT
        case gl.RGBA16UI, gl.RGB16UI, gl.RG16UI, gl.R16UI:
            return gl.UNSIGNED_SHORT
        case gl.RGBA8, gl.RGB8, gl.RG8, gl.R8:
            return gl.UNSIGNED_BYTE
        case gl.RGBA8UI, gl.RGB8UI, gl.RG8UI, gl.R8UI:
            return gl.UNSIGNED_BYTE
    }
    return 0
}

compile_shader::proc(ref: u32, shader_source_param: string) {
    b := strings.builder_make()
    strings.write_string(&b, "#version 330\n")
    strings.write_string(&b, shader_source_param)
    shader_source: string = strings.to_string(b)
    buf := [512]u8 {}
    shader_source_cstr := strings.clone_to_cstring(shader_source)
    gl.ShaderSource(ref, 1, &shader_source_cstr, nil)
    gl.CompileShader(ref)
    status: i32
    gl.GetShaderiv(ref, gl.COMPILE_STATUS, &status)
    gl.GetShaderInfoLog(ref, 512, nil, &buf[0])
    if bool(status) != gl.TRUE {
        // TODO: Proper error handling
        fmt.printf("%s\n%s\n", "Shader compilation failed: ", buf)
    }

}

program_from_paths::proc(
    vertex_path: string, fragment_path: string) -> glsl_program {
    fmt.printf("Compiling %s.\n", fragment_path)
    vs_ref: u32 = shader_from_path(vertex_path, gl.VERTEX_SHADER)
    fs_ref: u32 = shader_from_path(fragment_path, gl.FRAGMENT_SHADER)
    program: u32 = gl.CreateProgram()
    if program == 0 {
        // TODO: do proper error handling
        fmt.println("Unable to create program.\n")
    }
    gl.AttachShader(program, vs_ref)
    gl.AttachShader(program, fs_ref)
    gl.LinkProgram(program)
    status: b32;
    BUF_SIZE: u32: 512
    buf: [BUF_SIZE]u8 = {}
    gl.GetProgramiv(program, gl.LINK_STATUS, (^i32)(&status))
    gl.GetProgramInfoLog(program, i32(BUF_SIZE), nil, &buf[0])
    if status != gl.TRUE {
        // TODO: do proper error handling
        fmt.printf("%s\n%s\n", "Failed to link program", buf)
    }
    gl.UseProgram(program)
    return glsl_program(program)
}

shader_from_path::proc(shader_path: string, shader_type: u32) -> u32 {
    data, is_success := os.read_entire_file_from_filename(shader_path)
    if !is_success {
        // TODO: Proper error handling
        fmt.printf("Unable to read file %s.\n", shader_path)
        return 0
    }
    // fmt.printf("%s\n", data)
    b := strings.builder_make()
    strings.write_bytes(&b, data[:])
    shader_contents: string = strings.to_string(b)
    return shader_from_source(shader_contents, shader_type)
}

shader_from_source::proc(shader_source: string, shader_type: u32) -> u32 {
    ref: u32 = gl.CreateShader(shader_type)
    if ref == 0 {
        // TODO: Proper error handling
        fmt.printf("Unable to create shader (error code %d)\n", \
                   gl.GetError())
        return 0
    }
    compile_shader(ref, shader_source)
    return ref
}

unbind::proc() {
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
}

@(private="file")
s_frame_count: u32 = 0
