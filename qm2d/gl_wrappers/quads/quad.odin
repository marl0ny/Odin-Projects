/* Package for creating and manipulating OpenGL quad screen frame objects.
 */
package quads

import "core:strings"
import "core:fmt"
import "core:os"

import gl "vendor:OpenGL"
import "../"


Quad::struct {
    id: u32,
    params: gl_wrappers.TextureParams,
    texture: u32,
    fbo: u32,
}

new::proc(t: gl_wrappers.TextureParams) -> Quad {
    for id, recycled_quad in s_recycled_quads {
        if recycled_quad.params == t {
            delete_key(&s_recycled_quads, id)
            return recycled_quad
        }
    }
    quad := Quad {
        id = gl_wrappers.acquire_new_frame(),
        params = t,
    }
    init_quad_texture(&quad)
    init_quad_buffer(&quad)
    gl_wrappers.unbind()
    return quad
}

make_program::proc(frag_shader_loc: string) -> gl_wrappers.glsl_program {
    using gl_wrappers
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

draw::proc(
    dst: Quad,
    program: gl_wrappers.glsl_program, uniforms: map[string]Uniform) {
    using gl_wrappers
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
    gl_wrappers.unbind()
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
    using gl_wrappers
    gl.BindVertexArray(s_quad_objects.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, s_quad_objects.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, s_quad_objects.ebo)
    if quad.id != 0 {
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo)
    }
    gl.ActiveTexture(gl.TEXTURE0 + quad.id)
    gl.BindTexture(gl.TEXTURE_2D, quad.texture)
    gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 
                     quad.params.width, quad.params.height,
                     to_base(quad.params.format), 
                     to_type(quad.params.format), array)
    gl_wrappers.unbind()
}

fill_array::proc(array: rawptr, quad: Quad) {
    using gl_wrappers
    gl.BindVertexArray(s_quad_objects.vao)
    gl.BindVertexArray(s_quad_objects.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER,  s_quad_objects.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,  s_quad_objects.ebo)
    if quad.id != 0 {
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo)
    }
    gl.ActiveTexture(gl.TEXTURE0 + quad.id)
    gl.BindTexture(gl.TEXTURE_2D, quad.texture)
    gl.ReadPixels(0, 0, quad.params.width, quad.params.height,
                  to_base(quad.params.format), 
                  to_type(quad.params.format),
                  array)
    gl_wrappers.unbind()
}

@private
Uniform::union {
    b32, i32, f32,
    gl_wrappers.Vec2,
    gl_wrappers.Vec3,
    gl_wrappers.Vec4,
    gl_wrappers.IVec2,
    gl_wrappers.IVec3,
    gl_wrappers.IVec4,
    Quad
}

@(private="file")
QuadObjects::struct {
    is_initialized: b32,
    vao: u32,
    vbo: u32,
    ebo: u32,
}

@(private="file")
s_quad_objects := QuadObjects {is_initialized=false}

@(private="file")
s_recycled_quads := map[u32]Quad {}

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
init_quad_texture::proc(quad: ^Quad) {
    using gl_wrappers
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
    if (!s_quad_objects.is_initialized) {
        gl.GenVertexArrays(1, &s_quad_objects.vao)
        gl.BindVertexArray(s_quad_objects.vao)
        gl.GenBuffers(1, &s_quad_objects.vbo)
        gl.BindBuffer(gl.ARRAY_BUFFER, s_quad_objects.vbo)
        quad_vertices := get_quad_vertices()
        quad_elements := get_quad_elements()
        gl.BufferData(gl.ARRAY_BUFFER, 
                      size_of(quad_vertices),
                      &quad_vertices[0], gl.STATIC_DRAW)
        gl.GenBuffers(1, &s_quad_objects.ebo)
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, s_quad_objects.ebo)
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, 
                      size_of(quad_elements),
                      &quad_elements[0], gl.STATIC_DRAW)
        s_quad_objects.is_initialized = true;
    }
    if (quad.id != 0) {
        gl.GenFramebuffers(1, &quad.fbo);
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo);
        gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0,
                                gl.TEXTURE_2D, quad.texture, 0);
    }
}

@(private="file")
bind_quad::proc(quad: Quad, program: gl_wrappers.glsl_program) {
    gl.UseProgram(u32(program))
    gl.BindVertexArray(s_quad_objects.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, s_quad_objects.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, s_quad_objects.ebo)
    if (quad.id != 0) {
        gl.BindFramebuffer(gl.FRAMEBUFFER, quad.fbo)
        gl.Clear(gl.COLOR_BUFFER_BIT)
    }
    attrib: i32 = gl.GetAttribLocation(u32(program), "position")
    gl.EnableVertexAttribArray(u32(attrib))
    gl.VertexAttribPointer(u32(attrib), 3, gl.FLOAT, gl.FALSE, 12, 0)
}
