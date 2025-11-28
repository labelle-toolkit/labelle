//! Example 06: Visual Effects
//!
//! This example demonstrates:
//! - Fade effects (fade in/out)
//! - Temporal fade (time-of-day)
//! - Flash effects
//!
//! Run with: zig build run-example-06

const std = @import("std");
const rl = @import("raylib");
const ecs = @import("ecs");
const gfx = @import("raylib-ecs-gfx");

const Position = struct {
    x: f32 = 0,
    y: f32 = 0,
};

pub fn main() !void {
    // CI test mode - hidden window, auto-screenshot and exit
    const ci_test = std.posix.getenv("CI_TEST") != null;
    if (ci_test) {
        rl.setConfigFlags(.{ .window_hidden = true });
    }

    // Initialize raylib
    rl.initWindow(800, 600, "Example 06: Visual Effects");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize ECS registry
    var registry = ecs.Registry.init(allocator);
    defer registry.deinit();

    // Create entities for different effects

    // 1. Fade In entity
    const fade_in_entity = registry.create();
    registry.add(fade_in_entity, Position{ .x = 150, .y = 200 });
    registry.add(fade_in_entity, gfx.Render{
        .z_index = 10,
        .sprite_name = "fade_in",
        .tint = rl.Color{ .r = 100, .g = 200, .b = 100, .a = 0 },
    });
    registry.add(fade_in_entity, gfx.effects.Fade{
        .alpha = 0,
        .target_alpha = 1.0,
        .speed = 0.5,
    });

    // 2. Fade Out entity
    const fade_out_entity = registry.create();
    registry.add(fade_out_entity, Position{ .x = 350, .y = 200 });
    registry.add(fade_out_entity, gfx.Render{
        .z_index = 10,
        .sprite_name = "fade_out",
        .tint = rl.Color{ .r = 200, .g = 100, .b = 100, .a = 255 },
    });
    registry.add(fade_out_entity, gfx.effects.Fade{
        .alpha = 1.0,
        .target_alpha = 0.0,
        .speed = 0.3,
    });

    // 3. Temporal fade entity (day/night cycle)
    const temporal_entity = registry.create();
    registry.add(temporal_entity, Position{ .x = 550, .y = 200 });
    registry.add(temporal_entity, gfx.Render{
        .z_index = 10,
        .sprite_name = "temporal",
        .tint = rl.Color.yellow,
    });
    registry.add(temporal_entity, gfx.effects.TemporalFade{
        .fade_start_hour = 18.0, // 6 PM
        .fade_end_hour = 22.0, // 10 PM
        .min_alpha = 0.2,
    });

    // 4. Flash entity
    const flash_entity = registry.create();
    registry.add(flash_entity, Position{ .x = 400, .y = 400 });
    registry.add(flash_entity, gfx.Render{
        .z_index = 10,
        .sprite_name = "flash",
        .tint = rl.Color.blue,
    });

    // Simulated game time (0-24 hours)
    var game_hour: f32 = 12.0; // Start at noon
    var time_speed: f32 = 2.0; // Hours per real second

    var frame_count: u32 = 0;

    // Main loop
    while (!rl.windowShouldClose()) {
        frame_count += 1;
        if (ci_test) {
            if (frame_count == 30) rl.takeScreenshot("screenshot_06.png");
            if (frame_count == 35) break;
        }
        const dt = rl.getFrameTime();

        // Update game time
        game_hour += time_speed * dt;
        if (game_hour >= 24.0) game_hour -= 24.0;

        // Time controls
        if (rl.isKeyDown(rl.KeyboardKey.up)) {
            time_speed = @min(10.0, time_speed + 1.0 * dt);
        }
        if (rl.isKeyDown(rl.KeyboardKey.down)) {
            time_speed = @max(0.1, time_speed - 1.0 * dt);
        }

        // Reset fades with R
        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            // Reset fade in
            if (registry.tryGet(gfx.effects.Fade, fade_in_entity)) |fade| {
                fade.alpha = 0;
                fade.target_alpha = 1.0;
            }
            if (registry.tryGet(gfx.Render, fade_in_entity)) |render| {
                render.tint.a = 0;
            }

            // Reset fade out
            if (registry.tryGet(gfx.effects.Fade, fade_out_entity)) |fade| {
                fade.alpha = 1.0;
                fade.target_alpha = 0.0;
            }
            if (registry.tryGet(gfx.Render, fade_out_entity)) |render| {
                render.tint.a = 255;
            }
        }

        // Trigger flash with F
        if (rl.isKeyPressed(rl.KeyboardKey.f)) {
            // Store original tint
            const original = if (registry.tryGet(gfx.Render, flash_entity)) |r| r.tint else rl.Color.blue;

            // Add or reset flash component
            if (registry.has(gfx.effects.Flash, flash_entity)) {
                registry.remove(gfx.effects.Flash, flash_entity);
            }
            registry.add(flash_entity, gfx.effects.Flash{
                .duration = 0.15,
                .remaining = 0.15,
                .color = rl.Color.white,
                .original_tint = original,
            });
        }

        // Update effect systems
        gfx.effects.fadeUpdateSystem(&registry, dt);
        gfx.effects.temporalFadeSystem(&registry, game_hour);
        gfx.effects.flashUpdateSystem(&registry, dt);

        // Rendering
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        // Draw entities (placeholder rectangles)
        {
            var view = registry.view(.{ Position, gfx.Render }, .{});
            var iter = @TypeOf(view).Iterator.init(&view);
            while (iter.next()) |entity| {
                const pos = view.getConst(Position, entity);
                const render = view.getConst(gfx.Render, entity);

                rl.drawRectangle(
                    @intFromFloat(pos.x - 40),
                    @intFromFloat(pos.y - 40),
                    80,
                    80,
                    render.tint,
                );
                rl.drawRectangleLines(
                    @intFromFloat(pos.x - 40),
                    @intFromFloat(pos.y - 40),
                    80,
                    80,
                    rl.Color.white,
                );
            }
        }

        // Labels
        rl.drawText("Fade In", 115, 270, 16, rl.Color.white);
        rl.drawText("Fade Out", 310, 270, 16, rl.Color.white);
        rl.drawText("Temporal", 515, 270, 16, rl.Color.white);
        rl.drawText("Flash (F)", 360, 470, 16, rl.Color.white);

        // Current alpha values
        if (registry.tryGet(gfx.effects.Fade, fade_in_entity)) |fade| {
            var buf: [32:0]u8 = undefined;
            _ = std.fmt.bufPrintZ(&buf, "Alpha: {d:.2}", .{fade.alpha}) catch "?";
            rl.drawText(&buf, 115, 290, 12, rl.Color.light_gray);
        }
        if (registry.tryGet(gfx.effects.Fade, fade_out_entity)) |fade| {
            var buf: [32:0]u8 = undefined;
            _ = std.fmt.bufPrintZ(&buf, "Alpha: {d:.2}", .{fade.alpha}) catch "?";
            rl.drawText(&buf, 315, 290, 12, rl.Color.light_gray);
        }

        // UI
        rl.drawText("Visual Effects Example", 10, 10, 20, rl.Color.white);
        rl.drawText("R: Reset fades | F: Trigger flash | Up/Down: Time speed", 10, 40, 14, rl.Color.light_gray);

        // Time display
        const hours = @as(u32, @intFromFloat(game_hour));
        const minutes = @as(u32, @intFromFloat((game_hour - @as(f32, @floatFromInt(hours))) * 60));
        var time_buf: [64:0]u8 = undefined;
        _ = std.fmt.bufPrintZ(&time_buf, "Game Time: {d:0>2}:{d:0>2} (Speed: {d:.1}x)", .{
            hours,
            minutes,
            time_speed,
        }) catch "?";
        rl.drawText(&time_buf, 10, 60, 16, rl.Color.sky_blue);

        // Day/night indicator
        const is_night = game_hour >= 18.0 or game_hour < 6.0;
        const time_label = if (is_night) "Night" else if (game_hour < 12.0) "Morning" else "Afternoon";
        rl.drawText(time_label, 10, 80, 14, if (is_night) rl.Color.dark_blue else rl.Color.yellow);

        // Temporal fade info
        rl.drawText("Temporal fade: Dims from 6PM-10PM", 400, 550, 12, rl.Color.light_gray);

        rl.drawText("ESC: Exit", 10, 580, 14, rl.Color.light_gray);
    }
}
