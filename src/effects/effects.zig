//! Visual effects

const rl = @import("raylib");
const ecs = @import("ecs");
const components = @import("../components/components.zig");
const Render = components.Render;

/// Fade effect component
pub const Fade = struct {
    /// Current alpha (0.0 - 1.0)
    alpha: f32 = 1.0,
    /// Target alpha
    target_alpha: f32 = 1.0,
    /// Fade speed (alpha change per second)
    speed: f32 = 1.0,
    /// Whether to remove entity when fully faded out
    remove_on_fadeout: bool = false,
};

/// Temporal fade based on time of day (0.0 - 24.0 hours)
pub const TemporalFade = struct {
    /// Hour when fade starts (e.g., 18.0 for 6 PM)
    fade_start_hour: f32 = 18.0,
    /// Hour when fully faded (e.g., 22.0 for 10 PM)
    fade_end_hour: f32 = 22.0,
    /// Minimum alpha at full fade
    min_alpha: f32 = 0.3,
};

/// Update fade effects
pub fn fadeUpdateSystem(
    registry: *ecs.Registry,
    dt: f32,
) void {
    var view = registry.view(.{ Fade, Render }, .{});
    var iter = @TypeOf(view).Iterator.init(&view);

    while (iter.next()) |entity| {
        var fade = view.get(Fade, entity);
        var render = view.get(Render, entity);

        // Move alpha toward target
        if (fade.alpha < fade.target_alpha) {
            fade.alpha = @min(fade.alpha + fade.speed * dt, fade.target_alpha);
        } else if (fade.alpha > fade.target_alpha) {
            fade.alpha = @max(fade.alpha - fade.speed * dt, fade.target_alpha);
        }

        // Apply alpha to render tint
        render.tint.a = @intFromFloat(fade.alpha * 255.0);

        // Check for removal
        if (fade.remove_on_fadeout and fade.alpha <= 0.01) {
            registry.destroy(entity);
        }
    }
}

/// Update temporal fade based on game time
pub fn temporalFadeSystem(
    registry: *ecs.Registry,
    current_hour: f32,
) void {
    var view = registry.view(.{ TemporalFade, Render }, .{});
    var iter = @TypeOf(view).Iterator.init(&view);

    while (iter.next()) |entity| {
        const temporal = view.getConst(TemporalFade, entity);
        var render = view.get(Render, entity);

        // Calculate fade factor based on time
        var alpha: f32 = 1.0;

        if (current_hour >= temporal.fade_start_hour and current_hour < temporal.fade_end_hour) {
            // During fade period
            const progress = (current_hour - temporal.fade_start_hour) /
                (temporal.fade_end_hour - temporal.fade_start_hour);
            alpha = 1.0 - progress * (1.0 - temporal.min_alpha);
        } else if (current_hour >= temporal.fade_end_hour) {
            // Fully faded
            alpha = temporal.min_alpha;
        }

        render.tint.a = @intFromFloat(alpha * 255.0);
    }
}

/// Flash effect (quick alpha pulse)
pub const Flash = struct {
    /// Flash duration
    duration: f32 = 0.1,
    /// Time remaining
    remaining: f32 = 0.1,
    /// Flash color
    color: rl.Color = rl.Color.white,
    /// Original tint to restore
    original_tint: rl.Color = rl.Color.white,
};

/// Update flash effects
pub fn flashUpdateSystem(
    registry: *ecs.Registry,
    dt: f32,
) void {
    var view = registry.view(.{ Flash, Render }, .{});
    var iter = @TypeOf(view).Iterator.init(&view);

    while (iter.next()) |entity| {
        var flash = view.get(Flash, entity);
        var render = view.get(Render, entity);

        flash.remaining -= dt;

        if (flash.remaining <= 0) {
            // Restore original tint and remove flash component
            render.tint = flash.original_tint;
            registry.remove(Flash, entity);
        } else {
            // Apply flash color
            render.tint = flash.color;
        }
    }
}
