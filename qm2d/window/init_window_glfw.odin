package window

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

init_window::proc(width: i32, height: i32) -> glfw.WindowHandle {
    if !glfw.Init() {
        fmt.println("Unable to create window.")
        // TODO: Proper error handling.
    }
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2);
    // glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    // glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE);
    glfw.WindowHint(glfw.RESIZABLE, gl.TRUE);
    // If on macos divide by 2
    window := glfw.CreateWindow(width/2, height/2, "Window", nil, nil)
    // TODO: check if window is nil
    glfw.MakeContextCurrent(window)
    return window
}
