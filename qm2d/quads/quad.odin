/* Package for creating and manipulating OpenGL quad screen frame objects.
 */
 package quads

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

Uniform::union {
    b32, i32, f32,\
    Vec2, Vec3, Vec4,\
    IVec2, IVec3, IVec4,\
    Quad
}

Quad::struct {
    id: u32,
    params: TextureParams,
    texture: u32,
    vao: u32,
    vbo: u32,
    ebo: u32,
    fbo: u32,
}


new::proc(t: TextureParams) -> Quad {
    for id, recycled_quad in s_recycled_quads {
        if recycled_quad.params == t {
            delete_key(&s_recycled_quads, id)
            return recycled_quad
        }
    }
    quad := Quad {
        id = s_frame_count,
        params = t,
    }
    init_quad_texture(&quad)
    init_quad_buffer(&quad)
    s_frame_count += 1
    unbind()
    return quad
}

make_program::proc(frag_shader_loc: string) -> glsl_program {
    fmt.printf("Compiling %s.\n", frag_shader_loc)
    vs_ref: u32 = shader_from_source(
        QUAD_VERTEX_SHADER, gl.VERTEX_SHADER)
    fs_ref: u32 = shader_from_path(
        frag_shader_loc, gl.FRAGMENT_SHADER)
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

draw::proc(dst: Quad, program: glsl_program, uniforms: map[string]Uniform) {
    bind_quad(dst, program)
    for name, uniform in uniforms {
        loc: i32 = gl.GetUniformLocation(
            u32(program), strings.clone_to_cstring(name))
        switch val in uniform {
            case i32:
                gl.Uniform1i(loc, val)
            case b32:
                gl.Uniform1i(loc, i32(val))
            case f32:
                gl.Uniform1f(loc, val)
            case Vec2:
                gl.Uniform2f(loc, val.x, val.y)
            case Vec3:
                gl.Uniform3f(loc, val.x, val.y, val.z)
            case Vec4:
                gl.Uniform4f(loc, val.x, val.y, val.z, val.w)
            case IVec2:
                gl.Uniform2i(loc, val.x, val.y)
            case IVec3:
                gl.Uniform3i(loc, val.x, val.y, val.z)
            case IVec4:
                gl.Uniform4i(loc, val.x, val.y, val.z, val.w)
            case Quad:
                gl.Uniform1i(loc, i32(val.id))
        }
    }
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    unbind()
}

recycle::proc(q: ^Quad) {
    s_recycled_quads[q.id] = q^
    q.id = 0xffffffff
}

swap::proc(p: ^Quad, q: ^Quad) {
    tmp: Quad = p^
    p^ = q^
    q^ = tmp
}

substitute_array::proc(quad: Quad, array: rawptr) {
    gl.BindVertexArray(quad.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, quad.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad.ebo)
    if quad.id != 0 {
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo)
    }
    gl.ActiveTexture(gl.TEXTURE0 + quad.id)
    gl.BindTexture(gl.TEXTURE_2D, quad.texture)
    gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 
                     quad.params.width, quad.params.height,
                     to_base(quad.params.format), 
                     to_type(quad.params.format), array)
    unbind()
}

fill_array::proc(array: rawptr, quad: Quad) {
    gl.BindVertexArray(quad.vao)
    gl.BindVertexArray(quad.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER,  quad.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,  quad.ebo)
    if quad.id != 0 {
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo)
    }
    gl.ActiveTexture(gl.TEXTURE0 + quad.id)
    gl.BindTexture(gl.TEXTURE_2D, quad.texture)
    gl.ReadPixels(0, 0, quad.params.width, quad.params.height,
                  to_base(quad.params.format), 
                  to_type(quad.params.format),
                  array)
    unbind()
}

@(private="file")
s_recycled_quads := map[u32]Quad {}

@(private="file")
s_frame_count: u32 = 0

@(private="file")
QUAD_VERTEX_SHADER : string : "" +\
    "#if __VERSION__ <= 120\n" +\
    "attribute vec3 position;\n" +\
    "varying vec2 UV;\n" +\
    "#else\n" +\
    "in vec3 position;\n" +\
    "out highp vec2 UV;\n" +\
    "#endif\n" +\
    "\n" +\
    "void main() {\n" +\
    "    gl_Position = vec4(position.xyz, 1.0);\n" +\
    "    UV = position.xy/2.0 + vec2(0.5, 0.5);\n" +\
    "}\n"

@(private="file")
get_quad_vertices::proc() -> [12]f32 {
    return {
        -1.0, -1.0, 0.0,
        -1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, -1.0, 0.0
    }
}

@(private="file")
get_quad_elements::proc() -> [6]i32 {
    return {0, 1, 2, 0, 2, 3}
}

@(private="file")
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

@(private="file")
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

@(private="file")
init_quad_texture::proc(quad: ^Quad) {
    if quad.id == 0 {
        gl.ActiveTexture(gl.TEXTURE0)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER,
                         gl.LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER,
                         gl.LINEAR)
        return
    }
    gl.ActiveTexture(gl.TEXTURE0 + quad.id)
    gl.GenTextures(1, &quad.texture)
    gl.BindTexture(gl.TEXTURE_2D, quad.texture)
    params := quad.params
    gl.TexImage2D(gl.TEXTURE_2D, 0, params.format,
                  params.width, params.height, 0, 
                  u32(to_base(params.format)),
                  u32(to_type(params.format)), nil)
    if params.generate_mipmap {
        gl.GenerateMipmap(gl.TEXTURE_2D)
    }
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, params.wrap_s)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, params.wrap_t)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER,
                     params.min_filter)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER,
                     params.mag_filter)

}

@(private="file")
init_quad_buffer::proc(quad: ^Quad) {
    gl.GenVertexArrays(1, &quad.vao)
    gl.BindVertexArray(quad.vao)
    gl.GenBuffers(1, &quad.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, quad.vbo)
    quad_vertices := get_quad_vertices()
    quad_elements := get_quad_elements()
    gl.BufferData(gl.ARRAY_BUFFER, 
                  size_of(quad_vertices),
                  &quad_vertices[0], gl.STATIC_DRAW)
    gl.GenBuffers(1, &quad.ebo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, 
                  size_of(quad_elements),
                  &quad_elements[0], gl.STATIC_DRAW)
    if (quad.id != 0) {
        gl.GenFramebuffers(1, &quad.fbo);
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo);
        gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0,
                                gl.TEXTURE_2D, quad.texture, 0);
    }
}

@(private="file")
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

@(private="file")
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

@(private="file")
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

@(private="file")
bind_quad::proc(quad: Quad, program: glsl_program) {
    gl.UseProgram(u32(program))
    gl.BindVertexArray(quad.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, quad.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad.ebo)
    if (quad.id != 0) {
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo)
        gl.Clear(gl.COLOR_BUFFER_BIT)
    }
    attrib: i32 = gl.GetAttribLocation(u32(program), "position")
    gl.EnableVertexAttribArray(u32(attrib))
    gl.VertexAttribPointer(u32(attrib), 3, gl.FLOAT, gl.FALSE, 12, 0)
}

@(private="file")
unbind::proc() {
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
}
