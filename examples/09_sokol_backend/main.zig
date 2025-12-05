//! Example 09: Sokol Backend
//!
//! This example demonstrates using the sokol backend with labelle.
//! It validates that the Backend abstraction works with a non-raylib renderer.
//!
//! Note: This example uses sokol_app for window management and sokol_gfx/sgl
//! for rendering. The sokol backend provides an alternative to raylib.
//!
//! Run with: zig build run-example-09

const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sgl = sokol.gl;
const sapp = sokol.app;
const gfx = @import("labelle");

// Create types using the sokol backend
const SokolGfx = gfx.withBackend(gfx.SokolBackend);

// Animation type for this example
const AnimType = enum {
    idle,
    walk,

    pub fn config(self: AnimType) gfx.AnimConfig {
        return switch (self) {
            .idle => .{ .frames = 4, .frame_duration = 0.2 },
            .walk => .{ .frames = 6, .frame_duration = 0.15 },
        };
    }
};

const Animation = SokolGfx.AnimationT(AnimType);

// Global state for sokol callback pattern
const State = struct {
    allocator: std.mem.Allocator,
    pass_action: sg.PassAction,
    animation: Animation,
    position_x: f32 = 400,
    position_y: f32 = 300,
    frame_count: u32 = 0,
};

var state: State = undefined;

export fn init() void {
    // Initialize sokol_gfx
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    // Initialize sokol_gl for immediate-mode drawing
    sgl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    // Setup clear color
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.2, .b = 0.3, .a = 1.0 },
    };

    // Initialize animation
    state.animation = Animation.init(.idle);
    state.animation.z_index = gfx.ZIndex.characters;

    std.debug.print("Sokol backend initialized successfully!\n", .{});
    std.debug.print("Window size: {}x{}\n", .{ sapp.width(), sapp.height() });
}

export fn frame() void {
    state.frame_count += 1;

    // Get delta time
    const dt: f32 = @floatCast(sapp.frameDuration());

    // Update animation
    state.animation.update(dt);

    // Begin render pass
    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });

    // Setup sokol_gl for 2D drawing
    sgl.defaults();
    sgl.matrixModeProjection();
    sgl.loadIdentity();

    const w: f32 = @floatFromInt(sapp.width());
    const h: f32 = @floatFromInt(sapp.height());
    sgl.ortho(0, w, h, 0, -1, 1);

    sgl.matrixModeModelview();
    sgl.loadIdentity();

    // Draw a colored rectangle to show the animation position
    const size: f32 = 60;
    const x = state.position_x - size / 2;
    const y = state.position_y - size / 2;

    // Change color based on animation type
    const color = if (state.animation.anim_type == .idle)
        SokolGfx.Color{ .r = 100, .g = 200, .b = 100, .a = 255 }
    else
        SokolGfx.Color{ .r = 100, .g = 100, .b = 200, .a = 255 };

    // Draw the rectangle using sokol backend
    gfx.SokolBackend.drawRectangle(
        @intFromFloat(x),
        @intFromFloat(y),
        @intFromFloat(size),
        @intFromFloat(size),
        color,
    );

    // Draw frame indicator
    const frame_size: f32 = 15;
    const frame_x = state.position_x - 30 + @as(f32, @floatFromInt(state.animation.frame)) * frame_size;
    gfx.SokolBackend.drawRectangle(
        @intFromFloat(frame_x),
        @intFromFloat(state.position_y + 40),
        @intFromFloat(frame_size - 2),
        10,
        SokolGfx.Color{ .r = 255, .g = 255, .b = 0, .a = 255 },
    );

    // Draw sgl commands
    sgl.draw();

    // End render pass
    sg.endPass();
    sg.commit();

    // Auto-exit for CI testing
    if (state.frame_count > 120) {
        sapp.quit();
    }
}

export fn cleanup() void {
    sgl.shutdown();
    sg.shutdown();
    std.debug.print("Sokol backend cleanup complete.\n", .{});
}

export fn event(ev: ?*const sapp.Event) void {
    const e = ev orelse return;

    if (e.type == .KEY_DOWN) {
        switch (e.key_code) {
            .ESCAPE => sapp.quit(),
            .SPACE => {
                // Toggle animation
                if (state.animation.anim_type == .idle) {
                    state.animation.play(.walk);
                } else {
                    state.animation.play(.idle);
                }
            },
            else => {},
        }
    }
}

pub fn main() !void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Store state for callbacks
    state = .{
        .allocator = allocator,
        .pass_action = .{},
        .animation = Animation.init(.idle),
    };

    // Run sokol app
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 800,
        .height = 600,
        .window_title = "Example 09: Sokol Backend",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
