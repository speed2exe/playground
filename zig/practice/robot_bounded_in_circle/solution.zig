// Calculate the final vector of how the robot travels after executing all
// instructions once - it consists of a change in position plus a change in
// direction.

// The robot stays in the circle if and only if (looking at the final vector)
// it changes direction (ie. doesn't stay pointing north), or it moves 0.

const std = @import("std");
const expect = std.testing.expect;

const Instruction = enum {
    move_forward,
    turn_left,
    turn_right,
};

const Facing = enum {
    forward,
    backward,
    left,
    right,
};

pub fn bounded_in_circle(instructions: []Instruction) bool {
    const eval_result = evaluateRelativeFinalPosition(instructions);
    if (eval_result.relative_X == 0 and eval_result.relative_Y == 0) {
        return true;
    }

    return eval_result.facing != Facing.forward;
}

// TODO: conversion of string to []Instruction

test "bounded_in_circle - 1" {
    var instructions = [_]Instruction{
        Instruction.move_forward,
        Instruction.turn_right,
    };
    try expect(bounded_in_circle(&instructions) == true);
}

test "bounded_in_circle - 2" {
    var instructions = [_]Instruction{
        Instruction.move_forward,
        Instruction.turn_right,
        Instruction.turn_left,
    };
    try expect(bounded_in_circle(&instructions) == false);
}

const EvalResult = struct {
    relative_X: usize,
    relative_Y: usize,
    facing: Facing,
};

fn evaluateRelativeFinalPosition(instructions: []const Instruction) EvalResult {
    // initial values
    var pos_X: usize = 0;
    var pos_Y: usize = 0;
    var facing: Facing = Facing.forward;

    for (instructions) |instruction| {
        switch (instruction) {
            Instruction.move_forward => {
                switch (facing) {
                    Facing.forward => {
                        pos_Y = pos_Y + 1;
                    },
                    Facing.backward => {
                        pos_Y = pos_Y - 1;
                    },
                    Facing.left => {
                        pos_X = pos_X - 1;
                    },
                    Facing.right => {
                        pos_X = pos_X + 1;
                    },
                }
            },
            Instruction.turn_right => {
                switch (facing) {
                    Facing.forward => {
                        facing = Facing.right;
                    },
                    Facing.backward => {
                        facing = Facing.left;
                    },
                    Facing.left => {
                        facing = Facing.forward;
                    },
                    Facing.right => {
                        facing = Facing.backward;
                    },
                }
            },
            Instruction.turn_left => {
                switch (facing) {
                    Facing.forward => {
                        facing = Facing.left;
                    },
                    Facing.backward => {
                        facing = Facing.right;
                    },
                    Facing.left => {
                        facing = Facing.backward;
                    },
                    Facing.right => {
                        facing = Facing.forward;
                    },
                }
            },
        }
    }

    return EvalResult{
        .facing = facing,
        .relative_X = pos_X,
        .relative_Y = pos_Y,
    };
}
