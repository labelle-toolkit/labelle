// Systems tests
//
// Note: ECS systems have been removed from labelle.
// These tests now focus on effect types and animation logic that can be
// tested without an ECS registry.

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
    run,
    jump,

    pub fn config(self: @This()) gfx.AnimConfig {
        return switch (self) {
            .idle => .{ .frames = 4, .frame_duration = 0.2 },
            .walk => .{ .frames = 6, .frame_duration = 0.1 },
            .run => .{ .frames = 8, .frame_duration = 0.08 },
            .jump => .{ .frames = 3, .frame_duration = 0.15, .looping = false },
        };
    }
};

const TestAnimation = gfx.Animation(TestAnim);

// ============================================================================
// Animation Logic Tests
// ============================================================================

pub const AnimationLogicTests = struct {
    test "animation advances frames correctly" {
        var anim = TestAnimation.init(.idle); // 4 frames, 0.2 duration

        // Frame 0 initially
        try expect.equal(anim.frame, 0);

        // Update by 0.25 (should advance to frame 1)
        anim.update(0.25);
        try expect.equal(anim.frame, 1);

        // Update by 0.2 (should advance to frame 2)
        anim.update(0.2);
        try expect.equal(anim.frame, 2);
    }

    test "non-looping animation stops at last frame" {
        var anim = TestAnimation.init(.jump); // 3 frames, 0.15 duration, non-looping

        // Update enough to reach the end
        anim.update(0.5); // Should be enough to reach last frame

        try expect.equal(anim.frame, 2); // 0-indexed, so frame 2 is last
        try expect.toBeFalse(anim.playing);
    }

    test "looping animation wraps around" {
        var anim = TestAnimation.init(.idle); // 4 frames, 0.2 duration, looping
        anim.frame = 3; // Set to last frame
        anim.elapsed_time = 0.19;

        // Update to trigger wrap
        anim.update(0.02);

        try expect.equal(anim.frame, 0); // Wrapped back to start
        try expect.toBeTrue(anim.playing);
    }

    test "play resets animation state" {
        var anim = TestAnimation.init(.idle);
        anim.frame = 2;
        anim.elapsed_time = 0.5;
        anim.playing = false;

        anim.play(.walk);

        try expect.equal(anim.anim_type, .walk);
        try expect.equal(anim.frame, 0);
        try expect.equal(anim.elapsed_time, 0);
        try expect.toBeTrue(anim.playing);
    }
};

// ============================================================================
// Effect Types Tests
// ============================================================================

pub const EffectTests = struct {
    test "Fade effect default values" {
        const fade = gfx.Fade{};

        try expect.equal(fade.alpha, 1.0);
        try expect.equal(fade.target_alpha, 1.0);
        try expect.equal(fade.speed, 1.0);
        try expect.toBeFalse(fade.remove_on_fadeout);
    }

    test "Fade effect update increases alpha" {
        var fade = gfx.Fade{
            .alpha = 0.0,
            .target_alpha = 1.0,
            .speed = 2.0,
        };

        fade.update(0.25);
        try expect.equal(fade.alpha, 0.5);

        fade.update(0.25);
        try expect.equal(fade.alpha, 1.0);
    }

    test "Fade effect update decreases alpha" {
        var fade = gfx.Fade{
            .alpha = 1.0,
            .target_alpha = 0.0,
            .speed = 4.0,
        };

        fade.update(0.25);
        try expect.equal(fade.alpha, 0.0);
    }

    test "Fade effect isComplete" {
        var fade = gfx.Fade{
            .alpha = 0.99,
            .target_alpha = 1.0,
            .speed = 1.0,
        };

        try expect.toBeTrue(fade.isComplete());

        fade.alpha = 0.5;
        try expect.toBeFalse(fade.isComplete());
    }

    test "Fade effect shouldRemove" {
        var fade = gfx.Fade{
            .alpha = 0.005,
            .target_alpha = 0.0,
            .speed = 1.0,
            .remove_on_fadeout = true,
        };

        try expect.toBeTrue(fade.shouldRemove());

        fade.remove_on_fadeout = false;
        try expect.toBeFalse(fade.shouldRemove());

        fade.remove_on_fadeout = true;
        fade.alpha = 0.5;
        try expect.toBeFalse(fade.shouldRemove());
    }

    test "TemporalFade calculateAlpha before fade starts" {
        const temporal = gfx.TemporalFade{
            .fade_start_hour = 18.0,
            .fade_end_hour = 22.0,
            .min_alpha = 0.2,
        };

        const alpha = temporal.calculateAlpha(12.0);
        try expect.equal(alpha, 1.0);
    }

    test "TemporalFade calculateAlpha during fade" {
        const temporal = gfx.TemporalFade{
            .fade_start_hour = 18.0,
            .fade_end_hour = 22.0,
            .min_alpha = 0.2,
        };

        const alpha = temporal.calculateAlpha(20.0);
        // At 20.0, we're 50% through the fade (18-22 is 4 hours, 20 is 2 hours in)
        // Alpha should be 1.0 - 0.5 * (1.0 - 0.2) = 1.0 - 0.4 = 0.6
        try expect.equal(alpha, 0.6);
    }

    test "TemporalFade calculateAlpha after fade ends" {
        const temporal = gfx.TemporalFade{
            .fade_start_hour = 18.0,
            .fade_end_hour = 22.0,
            .min_alpha = 0.2,
        };

        const alpha = temporal.calculateAlpha(23.0);
        try expect.equal(alpha, 0.2);
    }

    test "Flash effect default values" {
        const flash = gfx.Flash{};

        try expect.equal(flash.duration, 0.1);
        try expect.equal(flash.remaining, 0.1);
    }

    test "Flash effect update" {
        var flash = gfx.Flash{
            .duration = 0.2,
            .remaining = 0.2,
        };

        flash.update(0.1);
        try expect.equal(flash.remaining, 0.1);

        flash.update(0.1);
        try expect.equal(flash.remaining, 0.0);
    }

    test "Flash effect isComplete" {
        var flash = gfx.Flash{
            .duration = 0.1,
            .remaining = 0.05,
        };

        try expect.toBeFalse(flash.isComplete());

        flash.update(0.1);
        try expect.toBeTrue(flash.isComplete());
    }
};

// ============================================================================
// Sprite Name Generation Tests
// ============================================================================

pub const SpriteNameTests = struct {
    test "sprite name generation with prefix" {
        var anim = TestAnimation.init(.idle);
        anim.frame = 2;

        var buffer: [64]u8 = undefined;
        const name = anim.getSpriteName("player", &buffer);

        try expect.toBeTrue(std.mem.eql(u8, name, "player/idle_0003"));
    }

    test "sprite name generation without prefix" {
        var anim = TestAnimation.init(.walk);
        anim.frame = 0;

        var buffer: [64]u8 = undefined;
        const name = anim.getSpriteName("", &buffer);

        try expect.toBeTrue(std.mem.eql(u8, name, "walk_0001"));
    }

    test "sprite name updates with frame changes" {
        var anim = TestAnimation.init(.run);
        var buffer: [64]u8 = undefined;

        anim.frame = 0;
        var name = anim.getSpriteName("character", &buffer);
        try expect.toBeTrue(std.mem.eql(u8, name, "character/run_0001"));

        anim.frame = 4;
        name = anim.getSpriteName("character", &buffer);
        try expect.toBeTrue(std.mem.eql(u8, name, "character/run_0005"));

        anim.frame = 7; // Last frame of run (8 frames total)
        name = anim.getSpriteName("character", &buffer);
        try expect.toBeTrue(std.mem.eql(u8, name, "character/run_0008"));
    }
};

// Entry point for zspec
comptime {
    _ = zspec.runAll(@This());
}
