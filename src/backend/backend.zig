//! Graphics Backend Interface
//!
//! Defines the comptime interface for graphics backends.
//! Backends must provide types and functions for rendering.

const std = @import("std");

/// Creates a validated backend interface from an implementation type.
/// The implementation must provide all required types and functions.
///
/// Example usage:
/// ```zig
/// const MyBackend = Backend(RaylibImpl);
/// MyBackend.drawTexturePro(texture, src, dest, origin, rotation, tint);
/// ```
pub fn Backend(comptime Impl: type) type {
    // Compile-time validation: ensure Impl has all required types
    comptime {
        if (!@hasDecl(Impl, "Texture")) @compileError("Backend must define 'Texture' type");
        if (!@hasDecl(Impl, "Color")) @compileError("Backend must define 'Color' type");
        if (!@hasDecl(Impl, "Rectangle")) @compileError("Backend must define 'Rectangle' type");
        if (!@hasDecl(Impl, "Vector2")) @compileError("Backend must define 'Vector2' type");
        if (!@hasDecl(Impl, "Camera2D")) @compileError("Backend must define 'Camera2D' type");
    }

    // Compile-time validation: ensure Impl has all required functions
    comptime {
        if (!@hasDecl(Impl, "drawTexturePro")) @compileError("Backend must define 'drawTexturePro' function");
        if (!@hasDecl(Impl, "loadTexture")) @compileError("Backend must define 'loadTexture' function");
        if (!@hasDecl(Impl, "unloadTexture")) @compileError("Backend must define 'unloadTexture' function");
        if (!@hasDecl(Impl, "beginMode2D")) @compileError("Backend must define 'beginMode2D' function");
        if (!@hasDecl(Impl, "endMode2D")) @compileError("Backend must define 'endMode2D' function");
        if (!@hasDecl(Impl, "getScreenWidth")) @compileError("Backend must define 'getScreenWidth' function");
        if (!@hasDecl(Impl, "getScreenHeight")) @compileError("Backend must define 'getScreenHeight' function");
        if (!@hasDecl(Impl, "screenToWorld")) @compileError("Backend must define 'screenToWorld' function");
        if (!@hasDecl(Impl, "worldToScreen")) @compileError("Backend must define 'worldToScreen' function");
    }

    // Compile-time validation: ensure Impl has color constants
    comptime {
        if (!@hasDecl(Impl, "white")) @compileError("Backend must define 'white' color constant");
        if (!@hasDecl(Impl, "black")) @compileError("Backend must define 'black' color constant");
        if (!@hasDecl(Impl, "red")) @compileError("Backend must define 'red' color constant");
        if (!@hasDecl(Impl, "green")) @compileError("Backend must define 'green' color constant");
        if (!@hasDecl(Impl, "blue")) @compileError("Backend must define 'blue' color constant");
        if (!@hasDecl(Impl, "transparent")) @compileError("Backend must define 'transparent' color constant");
    }

    return struct {
        const Self = @This();

        /// The underlying implementation type
        pub const Implementation = Impl;

        // Types
        pub const Texture = Impl.Texture;
        pub const Color = Impl.Color;
        pub const Rectangle = Impl.Rectangle;
        pub const Vector2 = Impl.Vector2;
        pub const Camera2D = Impl.Camera2D;

        // Color constants
        pub const white = Impl.white;
        pub const black = Impl.black;
        pub const red = Impl.red;
        pub const green = Impl.green;
        pub const blue = Impl.blue;
        pub const transparent = Impl.transparent;

        /// Create a color from RGBA values
        pub inline fn color(r: u8, g: u8, b: u8, a: u8) Color {
            if (@hasDecl(Impl, "color")) {
                return Impl.color(r, g, b, a);
            } else {
                return .{ .r = r, .g = g, .b = b, .a = a };
            }
        }

        /// Create a rectangle
        pub inline fn rectangle(x: f32, y: f32, width: f32, height: f32) Rectangle {
            if (@hasDecl(Impl, "rectangle")) {
                return Impl.rectangle(x, y, width, height);
            } else {
                return .{ .x = x, .y = y, .width = width, .height = height };
            }
        }

        /// Create a vector2
        pub inline fn vector2(x: f32, y: f32) Vector2 {
            if (@hasDecl(Impl, "vector2")) {
                return Impl.vector2(x, y);
            } else {
                return .{ .x = x, .y = y };
            }
        }

        // Drawing functions

        /// Draw a texture with full control over source/dest rectangles, rotation, and tint
        pub inline fn drawTexturePro(
            texture: Texture,
            source: Rectangle,
            dest: Rectangle,
            origin: Vector2,
            rotation: f32,
            tint: Color,
        ) void {
            Impl.drawTexturePro(texture, source, dest, origin, rotation, tint);
        }

        // Texture management

        /// Load a texture from file path
        pub inline fn loadTexture(path: [:0]const u8) !Texture {
            return Impl.loadTexture(path);
        }

        /// Unload a texture
        pub inline fn unloadTexture(texture: Texture) void {
            Impl.unloadTexture(texture);
        }

        // Camera functions

        /// Begin 2D camera mode
        pub inline fn beginMode2D(camera: Camera2D) void {
            Impl.beginMode2D(camera);
        }

        /// End 2D camera mode
        pub inline fn endMode2D() void {
            Impl.endMode2D();
        }

        /// Get screen width
        pub inline fn getScreenWidth() i32 {
            return Impl.getScreenWidth();
        }

        /// Get screen height
        pub inline fn getScreenHeight() i32 {
            return Impl.getScreenHeight();
        }

        /// Convert screen coordinates to world coordinates
        pub inline fn screenToWorld(pos: Vector2, camera: Camera2D) Vector2 {
            return Impl.screenToWorld(pos, camera);
        }

        /// Convert world coordinates to screen coordinates
        pub inline fn worldToScreen(pos: Vector2, camera: Camera2D) Vector2 {
            return Impl.worldToScreen(pos, camera);
        }

        // Optional functions (backends may or may not implement)

        /// Check if texture is valid
        pub inline fn isTextureValid(texture: Texture) bool {
            if (@hasDecl(Impl, "isTextureValid")) {
                return Impl.isTextureValid(texture);
            } else if (@hasField(Texture, "id")) {
                return texture.id != 0;
            } else {
                return true;
            }
        }
    };
}

/// Errors that can occur during backend operations
pub const BackendError = error{
    TextureLoadFailed,
    FileNotFound,
    InvalidFormat,
};
