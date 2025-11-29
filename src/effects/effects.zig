//! Visual effects

const ecs = @import("ecs");
const backend_mod = @import("../backend/backend.zig");
const raylib_backend = @import("../backend/raylib_backend.zig");
const components = @import("../components/components.zig");

/// Default backend for backwards compatibility
pub const DefaultBackend = backend_mod.Backend(raylib_backend.RaylibBackend);

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

/// Flash effect with custom backend support
pub fn FlashWith(comptime BackendType: type) type {
    return struct {
        /// Flash duration
        duration: f32 = 0.1,
        /// Time remaining
        remaining: f32 = 0.1,
        /// Flash color
        color: BackendType.Color = BackendType.white,
        /// Original tint to restore
        original_tint: BackendType.Color = BackendType.white,
    };
}

/// Flash effect (quick alpha pulse) - default raylib backend
pub const Flash = FlashWith(DefaultBackend);

/// Update fade effects (generic version)
pub fn fadeUpdateSystemWith(
    comptime BackendType: type,
    registry: *ecs.Registry,
    dt: f32,
) void {
    const Render = components.RenderWith(BackendType);
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

/// Update fade effects (default backend)
pub fn fadeUpdateSystem(
    registry: *ecs.Registry,
    dt: f32,
) void {
    fadeUpdateSystemWith(DefaultBackend, registry, dt);
}

/// Update temporal fade based on game time (generic version)
pub fn temporalFadeSystemWith(
    comptime BackendType: type,
    registry: *ecs.Registry,
    current_hour: f32,
) void {
    const Render = components.RenderWith(BackendType);
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

/// Update temporal fade based on game time (default backend)
pub fn temporalFadeSystem(
    registry: *ecs.Registry,
    current_hour: f32,
) void {
    temporalFadeSystemWith(DefaultBackend, registry, current_hour);
}

/// Update flash effects (generic version)
pub fn flashUpdateSystemWith(
    comptime BackendType: type,
    registry: *ecs.Registry,
    dt: f32,
) void {
    const Render = components.RenderWith(BackendType);
    const FlashType = FlashWith(BackendType);
    var view = registry.view(.{ FlashType, Render }, .{});
    var iter = @TypeOf(view).Iterator.init(&view);

    while (iter.next()) |entity| {
        var flash = view.get(FlashType, entity);
        var render = view.get(Render, entity);

        flash.remaining -= dt;

        if (flash.remaining <= 0) {
            // Restore original tint and remove flash component
            render.tint = flash.original_tint;
            registry.remove(FlashType, entity);
        } else {
            // Apply flash color
            render.tint = flash.color;
        }
    }
}

/// Update flash effects (default backend)
pub fn flashUpdateSystem(
    registry: *ecs.Registry,
    dt: f32,
) void {
    flashUpdateSystemWith(DefaultBackend, registry, dt);
}
