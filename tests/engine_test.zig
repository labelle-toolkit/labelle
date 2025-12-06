// Engine API tests
//
// Note: These tests focus on Engine configuration and
// component types. Actual rendering requires raylib window context
// and is tested via the examples.

const std = @import("std");
const zspec = @import("zspec");
const gfx = @import("labelle");

const expect = zspec.expect;

// ============================================================================
// Test Animation Type
// ============================================================================

const TestAnim = enum {
    idle,
    walk,
    attack,

    pub fn config(self: @This()) gfx.AnimConfig {
        return switch (self) {
            .idle => .{ .frames = 4, .frame_duration = 0.2 },
            .walk => .{ .frames = 6, .frame_duration = 0.1 },
            .attack => .{ .frames = 3, .frame_duration = 0.15, .looping = false },
        };
    }
};

const TestAnimation = gfx.Animation(TestAnim);

// ============================================================================
// Position Component Tests
// ============================================================================

pub const PositionTests = struct {
    test "Position default values" {
        const pos = gfx.Position{};

        try expect.equal(pos.x, 0);
        try expect.equal(pos.y, 0);
    }

    test "Position custom values" {
        const pos = gfx.Position{ .x = 100.5, .y = -50.25 };

        try expect.equal(pos.x, 100.5);
        try expect.equal(pos.y, -50.25);
    }
};

// ============================================================================
// Sprite Component Tests
// ============================================================================

pub const SpriteTests = struct {
    test "Sprite default values" {
        const sprite = gfx.Sprite{ .name = "test", .pivot = .center };

        try expect.equal(sprite.z_index, 0);
        try expect.equal(sprite.scale, 1.0);
        try expect.equal(sprite.rotation, 0);
        try expect.toBeFalse(sprite.flip_x);
        try expect.toBeFalse(sprite.flip_y);
        try expect.equal(sprite.offset_x, 0);
        try expect.equal(sprite.offset_y, 0);
    }

    test "Sprite custom values" {
        const sprite = gfx.Sprite{
            .name = "player_idle",
            .z_index = gfx.ZIndex.characters,
            .scale = 2.0,
            .rotation = 45.0,
            .flip_x = true,
            .offset_x = 10,
            .offset_y = -5,
            .pivot = .bottom_center,
        };

        try expect.toBeTrue(std.mem.eql(u8, sprite.name, "player_idle"));
        try expect.equal(sprite.z_index, gfx.ZIndex.characters);
        try expect.equal(sprite.scale, 2.0);
        try expect.equal(sprite.rotation, 45.0);
        try expect.toBeTrue(sprite.flip_x);
        try expect.equal(sprite.offset_x, 10);
        try expect.equal(sprite.offset_y, -5);
    }
};

// ============================================================================
// Engine Config Tests
// ============================================================================

pub const EngineConfigTests = struct {
    test "EngineConfig default values" {
        const config = gfx.EngineConfig{};

        try expect.equal(config.atlases.len, 0);
        try expect.toBeTrue(config.camera.initial_x == null);
        try expect.toBeTrue(config.camera.initial_y == null);
        try expect.equal(config.camera.initial_zoom, 1.0);
        try expect.toBeTrue(config.camera.bounds == null);
    }

    test "CameraConfig with bounds" {
        const config = gfx.CameraConfig{
            .initial_x = 100,
            .initial_y = 200,
            .initial_zoom = 2.0,
            .bounds = .{
                .min_x = 0,
                .min_y = 0,
                .max_x = 1600,
                .max_y = 1200,
            },
        };

        try expect.equal(config.initial_x, 100);
        try expect.equal(config.initial_y, 200);
        try expect.equal(config.initial_zoom, 2.0);
        try expect.toBeTrue(config.bounds != null);

        const bounds = config.bounds.?;
        try expect.equal(bounds.min_x, 0);
        try expect.equal(bounds.min_y, 0);
        try expect.equal(bounds.max_x, 1600);
        try expect.equal(bounds.max_y, 1200);
    }

    test "AtlasConfig structure" {
        const atlas = gfx.AtlasConfig{
            .name = "sprites",
            .json = "assets/sprites.json",
            .texture = "assets/sprites.png",
        };

        try expect.toBeTrue(std.mem.eql(u8, atlas.name, "sprites"));
        try expect.toBeTrue(std.mem.eql(u8, atlas.json, "assets/sprites.json"));
        try expect.toBeTrue(std.mem.eql(u8, atlas.texture, "assets/sprites.png"));
    }
};

// ============================================================================
// Animation Component Tests
// ============================================================================

pub const AnimationComponentTests = struct {
    test "Animation component initializes correctly" {
        const anim = TestAnimation.init(.idle);

        try expect.equal(anim.anim_type, .idle);
        try expect.equal(anim.frame, 0);
        try expect.toBeTrue(anim.playing);
    }

    test "Animation component plays different types" {
        var anim = TestAnimation.init(.idle);

        anim.play(.walk);
        try expect.equal(anim.anim_type, .walk);
        try expect.equal(anim.frame, 0);

        anim.play(.attack);
        try expect.equal(anim.anim_type, .attack);
        try expect.equal(anim.frame, 0);
    }

    test "Animation component has render properties" {
        var anim = TestAnimation.init(.idle);
        anim.z_index = gfx.ZIndex.characters;
        anim.scale = 2.0;
        anim.flip_x = true;

        try expect.equal(anim.z_index, gfx.ZIndex.characters);
        try expect.equal(anim.scale, 2.0);
        try expect.toBeTrue(anim.flip_x);
    }

    test "Animation component updates elapsed time" {
        var anim = TestAnimation.init(.idle);
        anim.update(0.05);

        try expect.equal(anim.elapsed_time, 0.05);
    }
};

// ============================================================================
// Z-Index Constants Tests
// ============================================================================

pub const ZIndexTests = struct {
    test "ZIndex constants are ordered correctly" {
        try expect.toBeTrue(gfx.ZIndex.background < gfx.ZIndex.floor);
        try expect.toBeTrue(gfx.ZIndex.floor < gfx.ZIndex.shadows);
        try expect.toBeTrue(gfx.ZIndex.shadows < gfx.ZIndex.items);
        try expect.toBeTrue(gfx.ZIndex.items < gfx.ZIndex.characters);
        try expect.toBeTrue(gfx.ZIndex.characters < gfx.ZIndex.effects);
        try expect.toBeTrue(gfx.ZIndex.effects < gfx.ZIndex.ui_background);
        try expect.toBeTrue(gfx.ZIndex.ui_background < gfx.ZIndex.ui);
        try expect.toBeTrue(gfx.ZIndex.ui < gfx.ZIndex.ui_foreground);
        try expect.toBeTrue(gfx.ZIndex.ui_foreground < gfx.ZIndex.overlay);
        try expect.toBeTrue(gfx.ZIndex.overlay < gfx.ZIndex.debug);
    }

    test "ZIndex values are as expected" {
        try expect.equal(gfx.ZIndex.background, 0);
        try expect.equal(gfx.ZIndex.floor, 10);
        try expect.equal(gfx.ZIndex.characters, 40);
        try expect.equal(gfx.ZIndex.ui, 70);
        try expect.equal(gfx.ZIndex.debug, 100);
    }
};

// Entry point for zspec
comptime {
    _ = zspec.runAll(@This());
}
