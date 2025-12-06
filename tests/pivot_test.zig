// Pivot point tests

const std = @import("std");
const zspec = @import("zspec");
const expect = zspec.expect;

const gfx = @import("labelle");
const Pivot = gfx.Pivot;

// ============================================================================
// Pivot Enum Tests
// ============================================================================

pub const PivotEnumTests = struct {
    test "getNormalized returns correct values for center" {
        const pivot = Pivot.center;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 0.5);
        try expect.equal(result.y, 0.5);
    }

    test "getNormalized returns correct values for top_left" {
        const pivot = Pivot.top_left;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 0.0);
        try expect.equal(result.y, 0.0);
    }

    test "getNormalized returns correct values for top_center" {
        const pivot = Pivot.top_center;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 0.5);
        try expect.equal(result.y, 0.0);
    }

    test "getNormalized returns correct values for top_right" {
        const pivot = Pivot.top_right;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 1.0);
        try expect.equal(result.y, 0.0);
    }

    test "getNormalized returns correct values for center_left" {
        const pivot = Pivot.center_left;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 0.0);
        try expect.equal(result.y, 0.5);
    }

    test "getNormalized returns correct values for center_right" {
        const pivot = Pivot.center_right;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 1.0);
        try expect.equal(result.y, 0.5);
    }

    test "getNormalized returns correct values for bottom_left" {
        const pivot = Pivot.bottom_left;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 0.0);
        try expect.equal(result.y, 1.0);
    }

    test "getNormalized returns correct values for bottom_center" {
        const pivot = Pivot.bottom_center;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 0.5);
        try expect.equal(result.y, 1.0);
    }

    test "getNormalized returns correct values for bottom_right" {
        const pivot = Pivot.bottom_right;
        const result = pivot.getNormalized(0, 0);
        try expect.equal(result.x, 1.0);
        try expect.equal(result.y, 1.0);
    }

    test "getNormalized uses custom values for custom pivot" {
        const pivot = Pivot.custom;
        const result = pivot.getNormalized(0.25, 0.75);
        try expect.equal(result.x, 0.25);
        try expect.equal(result.y, 0.75);
    }

    test "getOrigin calculates correct offset for center" {
        const pivot = Pivot.center;
        const result = pivot.getOrigin(100, 80, 0, 0);
        try expect.equal(result.x, 50.0);
        try expect.equal(result.y, 40.0);
    }

    test "getOrigin calculates correct offset for top_left" {
        const pivot = Pivot.top_left;
        const result = pivot.getOrigin(100, 80, 0, 0);
        try expect.equal(result.x, 0.0);
        try expect.equal(result.y, 0.0);
    }

    test "getOrigin calculates correct offset for bottom_right" {
        const pivot = Pivot.bottom_right;
        const result = pivot.getOrigin(100, 80, 0, 0);
        try expect.equal(result.x, 100.0);
        try expect.equal(result.y, 80.0);
    }

    test "getOrigin calculates correct offset for bottom_center" {
        const pivot = Pivot.bottom_center;
        const result = pivot.getOrigin(64, 128, 0, 0);
        try expect.equal(result.x, 32.0);
        try expect.equal(result.y, 128.0);
    }

    test "getOrigin calculates correct offset for custom" {
        const pivot = Pivot.custom;
        const result = pivot.getOrigin(100, 200, 0.1, 0.9);
        try expect.equal(result.x, 10.0);
        try expect.equal(result.y, 180.0);
    }
};

// ============================================================================
// Component Pivot Field Tests
// ============================================================================

pub const ComponentPivotTests = struct {
    test "Sprite component requires pivot field" {
        const sprite = gfx.Sprite{ .name = "test", .pivot = .center };
        try expect.equal(sprite.pivot, Pivot.center);
        try expect.equal(sprite.pivot_x, 0.5);
        try expect.equal(sprite.pivot_y, 0.5);
    }

    test "Sprite component accepts bottom_center pivot" {
        const sprite = gfx.Sprite{
            .name = "test",
            .pivot = .bottom_center,
        };
        try expect.equal(sprite.pivot, Pivot.bottom_center);
    }

    test "Sprite component accepts custom pivot coordinates" {
        const sprite = gfx.Sprite{
            .name = "test",
            .pivot = .custom,
            .pivot_x = 0.2,
            .pivot_y = 0.8,
        };
        try expect.equal(sprite.pivot, Pivot.custom);
        try expect.equal(sprite.pivot_x, 0.2);
        try expect.equal(sprite.pivot_y, 0.8);
    }

    test "Render component requires pivot field" {
        const render = gfx.Render{ .pivot = .center };
        try expect.equal(render.pivot, Pivot.center);
        try expect.equal(render.pivot_x, 0.5);
        try expect.equal(render.pivot_y, 0.5);
    }

    test "Render component accepts bottom_left pivot" {
        const render = gfx.Render{
            .pivot = .bottom_left,
        };
        try expect.equal(render.pivot, Pivot.bottom_left);
    }
};

// ============================================================================
// Animation Component Pivot Tests
// ============================================================================

const TestAnim = enum {
    idle,
    walk,

    pub fn config(self: @This()) gfx.AnimConfig {
        return switch (self) {
            .idle => .{ .frames = 4, .frame_duration = 0.2 },
            .walk => .{ .frames = 6, .frame_duration = 0.1 },
        };
    }
};

pub const AnimationPivotTests = struct {
    test "Animation component requires pivot field" {
        var anim = gfx.Animation(TestAnim).init(.idle);
        anim.pivot = .center;
        try expect.equal(anim.pivot, Pivot.center);
        try expect.equal(anim.pivot_x, 0.5);
        try expect.equal(anim.pivot_y, 0.5);
    }

    test "Animation component pivot can be set to bottom_center" {
        var anim = gfx.Animation(TestAnim).init(.idle);
        anim.pivot = .bottom_center;
        try expect.equal(anim.pivot, Pivot.bottom_center);
    }
};

// ============================================================================
// VisualEngine SpriteConfig Pivot Tests
// ============================================================================

pub const VisualEnginePivotTests = struct {
    test "SpriteConfig requires pivot field" {
        const config = gfx.visual_engine.SpriteConfig{ .pivot = .center };
        try expect.equal(config.pivot, Pivot.center);
        try expect.equal(config.pivot_x, 0.5);
        try expect.equal(config.pivot_y, 0.5);
    }

    test "SpriteConfig accepts pivot configuration" {
        const config = gfx.visual_engine.SpriteConfig{
            .sprite_name = "player",
            .x = 100,
            .y = 200,
            .pivot = .bottom_center,
        };
        try expect.equal(config.pivot, Pivot.bottom_center);
    }

    test "SpriteConfig accepts custom pivot coordinates" {
        const config = gfx.visual_engine.SpriteConfig{
            .sprite_name = "weapon",
            .pivot = .custom,
            .pivot_x = 0.1,
            .pivot_y = 0.9,
        };
        try expect.equal(config.pivot, Pivot.custom);
        try expect.equal(config.pivot_x, 0.1);
        try expect.equal(config.pivot_y, 0.9);
    }
};

// ============================================================================
// Pivot Export Tests
// ============================================================================

pub const PivotExportTests = struct {
    test "Pivot is exported from lib.zig" {
        // Verify that Pivot is accessible from the main library
        const p: gfx.Pivot = .center;
        try expect.equal(p, Pivot.center);
    }

    test "Pivot is exported from visual_engine" {
        const p: gfx.visual_engine.Pivot = .bottom_left;
        try expect.equal(p, Pivot.bottom_left);
    }

    test "all pivot variants are accessible" {
        // Verify all enum variants compile and are accessible
        const pivots = [_]Pivot{
            .center,
            .top_left,
            .top_center,
            .top_right,
            .center_left,
            .center_right,
            .bottom_left,
            .bottom_center,
            .bottom_right,
            .custom,
        };
        try expect.equal(pivots.len, 10);
    }
};

// Entry point for zspec
comptime {
    _ = zspec.runAll(@This());
}
