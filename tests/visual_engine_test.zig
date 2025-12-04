// Visual Engine Animation Tests

const std = @import("std");
const zspec = @import("zspec");
const expect = zspec.expect;

const gfx = @import("labelle");

pub const VisualEngineAnimationTests = struct {
    test "max sprite name length constant exists" {
        // Verify the constant is accessible and reasonable
        try expect.toBeTrue(gfx.visual_engine.max_sprite_name_len >= 32);
        try expect.toBeTrue(gfx.visual_engine.max_sprite_name_len <= 256);
    }

    test "max animation name length constant exists" {
        // Verify the constant is accessible and reasonable
        try expect.toBeTrue(gfx.visual_engine.max_animation_name_len >= 16);
        try expect.toBeTrue(gfx.visual_engine.max_animation_name_len <= 128);
    }

    test "SpriteId structure" {
        const id = gfx.visual_engine.SpriteId{ .index = 42, .generation = 7 };
        try expect.equal(id.index, 42);
        try expect.equal(id.generation, 7);
    }

    test "Position structure" {
        const pos = gfx.visual_engine.Position{ .x = 100.5, .y = 200.25 };
        try expect.equal(pos.x, 100.5);
        try expect.equal(pos.y, 200.25);
    }

    test "ZIndex constants are accessible" {
        try expect.toBeTrue(gfx.visual_engine.ZIndex.background < gfx.visual_engine.ZIndex.characters);
        try expect.toBeTrue(gfx.visual_engine.ZIndex.characters < gfx.visual_engine.ZIndex.ui);
    }

    test "SpriteConfig defaults" {
        const config = gfx.visual_engine.SpriteConfig{};
        try expect.equal(config.x, 0);
        try expect.equal(config.y, 0);
        try expect.equal(config.scale, 1.0);
        try expect.equal(config.rotation, 0);
        try expect.toBeTrue(config.visible);
        try expect.toBeFalse(config.flip_x);
        try expect.toBeFalse(config.flip_y);
    }

    test "EngineConfig defaults" {
        const config = gfx.visual_engine.EngineConfig{};
        try expect.toBeTrue(config.window == null);
        try expect.equal(config.clear_color_r, 40);
        try expect.equal(config.atlases.len, 0);
    }

    test "WindowConfig defaults" {
        const config = gfx.visual_engine.WindowConfig{};
        try expect.equal(config.width, 800);
        try expect.equal(config.height, 600);
        try expect.equal(config.target_fps, 60);
        try expect.toBeFalse(config.hidden);
    }
};
