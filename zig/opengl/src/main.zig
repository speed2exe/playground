const std = @import("std");

const c = @cImport({
    @cInclude("GLES/gl.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("GL/glew.h");
});

fn glfwSetErrorCallback(code: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("glfwSetErrorCallback: ({d}): {s}\n", .{ code, std.mem.span(description) });
}

pub fn main() !void {
    {
        const res = c.glfwSetErrorCallback(glfwSetErrorCallback);
        std.debug.print("c.glfwSetErrorCallback: {any}", .{res});
    }
    {
        const res = c.glfwInit();
        std.debug.print("k: {d}\n", .{res});
    }
    defer c.glfwTerminate();

    const window: *c.GLFWwindow = c.glfwCreateWindow(640, 480, "Hello, World", null, null) orelse {
        return std.debug.print("Failed to create window\n", .{});
    };
    c.glfwMakeContextCurrent(window);

    std.debug.print("OpenGL version: {s}\n", .{c.glGetString(c.GL_VERSION)});

    const positions: [6]c.GLfloat = .{
        -0.5, -0.5,
        0.0,  0.5,
        0.5,  -0.5,
    };

    var buffer: [1]c.GLuint = undefined;
    c.glGenBuffers(1, &buffer);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, buffer[0]);
    c.glBufferData(c.GL_ARRAY_BUFFER, 6 * @sizeOf(c.GLfloat), &positions, c.GL_STATIC_DRAW);

    // c.glVertexAttribPointer.?(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(c.GLfloat), null);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    while (c.glfwWindowShouldClose(window) == 0) {
        // Render here
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        // c.glBegin(c.GL_TRIANGLES);
        // c.glVertex2f(-0.5, -0.5);
        // c.glVertex2f(0.0, 0.5);
        // c.glVertex2f(0.5, -0.5);
        // c.glEnd();

        // Swap front and back buffers
        c.glfwSwapBuffers(window);

        // Poll for and process events
        c.glfwPollEvents();
    }
}
