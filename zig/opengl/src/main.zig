const std = @import("std");

const c = @cImport({
    @cInclude("GLFW/glfw3.h");
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

    while (c.glfwWindowShouldClose(window) == 0) {

        // Render here
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Swap front and back buffers
        c.glfwSwapBuffers(window);

        // Poll for and process events
        c.glfwPollEvents();
    }
}
