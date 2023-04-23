const std = @import("std");

const Lorry = struct {
    load: u32,

    pub fn info(self: Lorry) void {
        std.debug.print("Lorry load: {d}\n", .{self.load});
    }

    pub fn upgrade(self: *Lorry) void {
        self.load *= 2;
    }
};

const Roadster = struct {
    top_speed: f32,

    pub fn info(self: Roadster) void {
        std.debug.print("Roadster top speed: {d}\n", .{self.top_speed});
    }

    pub fn upgrade(self: *Roadster) void {
        self.top_speed *= 1.1;
    }
};

const Vehicle = union(enum) {
    Lorry: Lorry,
    Roadster: Roadster,

    pub inline fn info(self: Vehicle) void {
        switch (self) {
            inline else => |v| v.info(),
        }
    }

    pub inline fn upgrade(self: *Vehicle) void {
        switch (self.*) {
            inline else => |*v| v.upgrade(),
        }
    }
};

pub fn main() void {
    var vehicles: [2]Vehicle = undefined;
    vehicles[0] = .{ .Lorry = .{ .load = 1000 } };
    vehicles[1] = .{ .Roadster = .{ .top_speed = 200.0 } };
    for (vehicles) |vehicle| {
        vehicle.info();
    }
    for (&vehicles) |*vehicle| {
        vehicle.upgrade();
    }
    for (vehicles) |vehicle| {
        vehicle.info();
    }
}
