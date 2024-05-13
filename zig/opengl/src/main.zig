const std = @import("std");

const c = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    const k = c.glfwInit();
    std.debug.print("k = {any}\n", .{k});

    // const window: *c.GLFWwindow = null;
}
