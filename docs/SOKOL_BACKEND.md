# Sokol Backend Guide

The sokol backend provides an alternative to raylib for rendering, using sokol-zig bindings. This guide explains the key differences and how to properly use the sokol backend.

## Important: Callback-Based Architecture

Unlike raylib, sokol requires a **callback-based architecture**. This is a fundamental architectural difference that affects how you structure your application.

### Why This Matters

The sokol graphics library (`sokol_gfx`) requires a graphics context to be available before it can be initialized. This context is created by `sokol_app` internally, and is only available **inside the callbacks** that `sokol_app` invokes.

If you try to call sokol_gl functions (like `sgl.defaults()`) before this initialization, you'll get an assertion failure:

```
Assertion failed: ((0xABCDABCD) == _sgl.init_cookie), function sgl_defaults
```

### What Won't Work

The standard polling-style loop used with raylib **will not work** with sokol:

```zig
// THIS WILL NOT WORK with sokol backend:
const SokolGfx = gfx.withBackend(gfx.SokolBackend);
var engine = try SokolGfx.VisualEngine.init(allocator, config);

while (engine.isRunning()) {
    engine.beginFrame();  // Crashes here - sokol_gl not initialized
    engine.tick(dt);
    engine.endFrame();
}
```

### What Will Work

You must use sokol_app's callback pattern:

```zig
const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sgl = sokol.gl;
const sapp = sokol.app;
const gfx = @import("labelle");

// Global state for callbacks
var state: State = undefined;

export fn init() void {
    // Step 1: Initialize sokol_gfx
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    // Step 2: Initialize sokol_gl
    sgl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    // Step 3: Mark backend as initialized (enables drawing functions)
    gfx.SokolBackend.markInitialized();

    // Step 4: Initialize your game state
    // ...
}

export fn frame() void {
    const dt: f32 = @floatCast(sapp.frameDuration());

    // Update game logic
    // ...

    // Begin render pass (sokol-specific)
    sg.beginPass(.{
        .action = pass_action,
        .swapchain = sokol.glue.swapchain(),
    });

    // Use labelle's sokol backend for drawing
    gfx.SokolBackend.beginDrawing();

    // Draw your game
    gfx.SokolBackend.drawRectangle(100, 100, 50, 50, gfx.SokolBackend.red);

    gfx.SokolBackend.endDrawing();

    // End render pass
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    gfx.SokolBackend.markUninitialized();
    sgl.shutdown();
    sg.shutdown();
}

pub fn main() !void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .window_title = "My Sokol Game",
    });
}
```

## Initialization Lifecycle

The sokol backend provides lifecycle management functions:

| Function | When to Call | Purpose |
|----------|--------------|---------|
| `markInitialized()` | After `sgl.setup()` | Enables drawing functions |
| `markUninitialized()` | Before `sgl.shutdown()` | Disables drawing functions |
| `isInitialized()` | Anytime | Check if backend is ready |

## Feature Differences from Raylib

Some features work differently or are not available in the sokol backend:

| Feature | Raylib | Sokol |
|---------|--------|-------|
| Window creation | `initWindow()` | `sapp.run()` with config |
| Main loop | Polling (`while !shouldClose`) | Callbacks (`frame_cb`) |
| Frame timing | `setTargetFPS()` | VSync (configurable) |
| Text rendering | Built-in | Not available (use external) |
| Screenshots | `takeScreenshot()` | Not available |
| Input handling | `isKeyDown()`, etc. | Event callbacks |
| Texture loading | File path | Memory only |

## Texture Loading

The sokol backend does not have built-in file loading like raylib. You have two options:

### Option 1: Load from Memory

```zig
// Load image data yourself (e.g., using stb_image)
const pixels: []const u8 = loadImageData("sprite.png");
const texture = try gfx.SokolBackend.loadTextureFromMemory(pixels, width, height);
```

### Option 2: Use labelle's Texture Manager

The texture manager handles loading for you:

```zig
// In your init callback
var tex_manager = TextureManagerWith(gfx.SokolBackend).init(allocator);
try tex_manager.loadAtlas("sprites", "sprites.json", "sprites.png");
```

## Input Handling

Sokol uses event-based input rather than polling. Handle input in your event callback:

```zig
export fn event(ev: ?*const sapp.Event) void {
    const e = ev orelse return;

    if (e.type == .KEY_DOWN) {
        switch (e.key_code) {
            .ESCAPE => sapp.quit(),
            .SPACE => handleJump(),
            .LEFT => state.move_left = true,
            // ...
        }
    } else if (e.type == .KEY_UP) {
        switch (e.key_code) {
            .LEFT => state.move_left = false,
            // ...
        }
    }
}
```

## Complete Example

See `examples/09_sokol_backend/main.zig` for a complete working example.

## When to Use Sokol vs Raylib

| Use Sokol When | Use Raylib When |
|----------------|-----------------|
| You need WebGL/WASM support | You want simpler code structure |
| You're targeting multiple platforms | You prefer polling-style loops |
| You need more control over rendering | You want built-in text/font support |
| You're already using sokol elsewhere | You want file-based texture loading |

## Troubleshooting

### "SokolBackend not initialized" panic

You forgot to call `markInitialized()` after `sgl.setup()`, or you're trying to use a polling-style main loop.

### Assertion failure in `sgl_defaults`

You're calling sokol_gl functions before sokol_app has initialized the graphics context. Make sure all sokol_gl calls happen inside callbacks (init_cb, frame_cb).

### Drawing functions do nothing

Make sure you're calling `sg.beginPass()` before `beginDrawing()` and `sg.endPass()`/`sg.commit()` after `endDrawing()`.
