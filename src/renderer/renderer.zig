//! Main renderer for sprite and animation rendering

const std = @import("std");
const rl = @import("raylib");
const ecs = @import("ecs");

const components = @import("../components/components.zig");
const Render = components.Render;
const Animation = components.Animation;
const SpriteLocation = components.SpriteLocation;

const TextureManager = @import("../texture/texture_manager.zig").TextureManager;
const SpriteAtlas = @import("../texture/sprite_atlas.zig").SpriteAtlas;
const SpriteData = @import("../texture/sprite_atlas.zig").SpriteData;
const Camera = @import("../camera/camera.zig").Camera;

/// Predefined Z-index layers
pub const ZIndex = struct {
    pub const background: u8 = 0;
    pub const floor: u8 = 10;
    pub const shadows: u8 = 20;
    pub const items: u8 = 30;
    pub const characters: u8 = 40;
    pub const effects: u8 = 50;
    pub const ui_background: u8 = 60;
    pub const ui: u8 = 70;
    pub const ui_foreground: u8 = 80;
    pub const overlay: u8 = 90;
    pub const debug: u8 = 100;
};

/// Main renderer
pub const Renderer = struct {
    texture_manager: TextureManager,
    camera: Camera,
    allocator: std.mem.Allocator,

    /// Temporary buffer for sprite name generation
    sprite_name_buffer: [256]u8 = undefined,

    pub fn init(allocator: std.mem.Allocator) Renderer {
        return .{
            .texture_manager = TextureManager.init(allocator),
            .camera = Camera.init(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.texture_manager.deinit();
    }

    /// Load a sprite atlas
    /// Note: json_path and texture_path must be null-terminated string literals
    pub fn loadAtlas(
        self: *Renderer,
        name: []const u8,
        json_path: [:0]const u8,
        texture_path: [:0]const u8,
    ) !void {
        try self.texture_manager.loadAtlas(name, json_path, texture_path);
    }

    /// Draw a sprite by name at a position
    pub fn drawSprite(
        self: *Renderer,
        sprite_name: []const u8,
        x: f32,
        y: f32,
        options: DrawOptions,
    ) void {
        const found = self.texture_manager.findSprite(sprite_name) orelse return;
        self.drawSpriteData(found.atlas, found.sprite, x, y, options);
    }

    /// Draw a sprite using sprite data directly
    pub fn drawSpriteData(
        _: *Renderer,
        atlas: *SpriteAtlas,
        sprite: SpriteData,
        x: f32,
        y: f32,
        options: DrawOptions,
    ) void {
        // Source rectangle in the atlas
        var src_rect = rl.Rectangle{
            .x = @floatFromInt(sprite.x),
            .y = @floatFromInt(sprite.y),
            .width = @floatFromInt(sprite.width),
            .height = @floatFromInt(sprite.height),
        };

        // Calculate destination size
        // For rotated sprites, we need to swap width/height for the destination
        var dest_width: f32 = undefined;
        var dest_height: f32 = undefined;

        if (sprite.rotated) {
            // Rotated: atlas stores it rotated 90° CW, so width<->height are swapped
            dest_width = @as(f32, @floatFromInt(sprite.height)) * options.scale;
            dest_height = @as(f32, @floatFromInt(sprite.width)) * options.scale;
        } else {
            dest_width = @as(f32, @floatFromInt(sprite.width)) * options.scale;
            dest_height = @as(f32, @floatFromInt(sprite.height)) * options.scale;
        }

        // Apply flip to source rect
        if (options.flip_x) {
            src_rect.width = -src_rect.width;
        }
        if (options.flip_y) {
            src_rect.height = -src_rect.height;
        }

        // Calculate position with trim offset
        var draw_x = x + options.offset_x;
        var draw_y = y + options.offset_y;

        if (sprite.trimmed) {
            draw_x += @as(f32, @floatFromInt(sprite.offset_x)) * options.scale;
            draw_y += @as(f32, @floatFromInt(sprite.offset_y)) * options.scale;
        }

        const dest_rect = rl.Rectangle{
            .x = draw_x,
            .y = draw_y,
            .width = dest_width,
            .height = dest_height,
        };

        // Origin for rotation
        const origin = rl.Vector2{
            .x = dest_width / 2,
            .y = dest_height / 2,
        };

        // Calculate final rotation
        // If sprite is rotated in atlas, we need to counter-rotate by -90°
        var final_rotation = options.rotation;
        if (sprite.rotated) {
            final_rotation -= 90.0;
        }

        rl.drawTexturePro(
            atlas.texture,
            src_rect,
            dest_rect,
            origin,
            final_rotation,
            options.tint,
        );
    }

    /// Draw options for sprites
    pub const DrawOptions = struct {
        offset_x: f32 = 0,
        offset_y: f32 = 0,
        scale: f32 = 1.0,
        rotation: f32 = 0,
        tint: rl.Color = rl.Color.white,
        flip_x: bool = false,
        flip_y: bool = false,
    };

    /// Begin camera mode for world rendering
    pub fn beginCameraMode(self: *Renderer) void {
        rl.beginMode2D(self.camera.toRaylib());
    }

    /// End camera mode
    pub fn endCameraMode(_: *Renderer) void {
        rl.endMode2D();
    }

    /// Get the texture manager for advanced operations
    pub fn getTextureManager(self: *Renderer) *TextureManager {
        return &self.texture_manager;
    }

    /// Get the camera for manipulation
    pub fn getCamera(self: *Renderer) *Camera {
        return &self.camera;
    }
};
