# Claude Code Guidelines for labelle

## Project Overview

**labelle** is a 2D graphics library for Zig games that combines raylib rendering with zig-ecs (Entity Component System). It provides sprite rendering, animations, texture atlas support, camera controls, visual effects, and a self-contained visual engine.

## Tech Stack

- **Language**: Zig 0.15.x
- **Graphics**: raylib (via raylib-zig bindings), sokol (optional backend)
- **ECS**: zig-ecs (entt-style ECS)
- **Build**: Zig build system
- **Testing**: zspec (BDD-style testing)

## Project Structure

```
labelle/
├── src/
│   ├── lib.zig                 # Main exports - START HERE
│   ├── log.zig                 # Logging infrastructure
│   ├── components/             # ECS components (Position, Sprite, Animation, Render)
│   ├── animation/              # Animation system and player
│   ├── renderer/               # Sprite renderer and z-index
│   ├── texture/                # Texture/atlas management
│   ├── camera/                 # Camera system (pan, zoom, bounds)
│   ├── ecs/                    # ECS systems (render, animation update)
│   ├── effects/                # Visual effects (Fade, TemporalFade, Flash)
│   ├── engine/                 # High-level Engine API and VisualEngine
│   ├── backend/                # Backend abstraction (raylib, sokol, mock)
│   └── tools/                  # CLI tools (converter)
├── tests/                      # Test files (zspec)
├── examples/                   # Example applications (01-12)
├── fixtures/                   # Test assets (sprite atlases, .zon files)
└── .github/workflows/          # CI configuration
```

## Key Concepts

### Two Engine Options

1. **Engine** (ECS-based): Uses external zig-ecs registry, game owns entities
2. **VisualEngine** (Self-contained): Engine owns sprites internally via opaque handles

### VisualEngine (Recommended for new projects)

```zig
const gfx = @import("labelle");
const VisualEngine = gfx.visual_engine.VisualEngine;

var engine = try VisualEngine.init(allocator, .{
    .window = .{ .width = 800, .height = 600, .title = "My Game" },
    .atlases = &.{
        .{ .name = "sprites", .json = "assets/sprites.json", .texture = "assets/sprites.png" },
    },
});
defer engine.deinit();

// Create sprites - engine owns them internally
const player = try engine.addSprite(.{
    .sprite_name = "player_idle",
    .x = 400, .y = 300,
    .z_index = gfx.visual_engine.ZIndex.characters,
});

// Game loop
while (engine.isRunning()) {
    engine.setPosition(player, new_x, new_y);
    engine.beginFrame();
    engine.tick(dt);
    engine.endFrame();
}
```

### Engine API (ECS-based)

```zig
var engine = try gfx.Engine.init(allocator, &registry, .{
    .atlases = &.{
        .{ .name = "sprites", .json = "assets/sprites.json", .texture = "assets/sprites.png" },
    },
});
defer engine.deinit();

// Game loop
engine.render(dt);
engine.renderAnimations(Animations.Player, "player", dt);
```

### Animation System (config-based)

Animations use a `config()` method on enums to define frame count and timing:

```zig
const Animations = struct {
    const Player = enum {
        idle, walk, attack,

        pub fn config(self: @This()) gfx.AnimConfig {
            return switch (self) {
                .idle => .{ .frames = 4, .frame_duration = 0.2 },
                .walk => .{ .frames = 6, .frame_duration = 0.1 },
                .attack => .{ .frames = 5, .frame_duration = 0.08, .looping = false },
            };
        }
    };
};

// Usage
var anim = gfx.Animation(Animations.Player).init(.idle);
anim.play(.walk);  // Switch animation
anim.update(dt);   // Update each frame
```

### Comptime Animation Definitions

Load animation definitions from .zon files at compile time:

```zig
const character_frames = @import("characters_frames.zon");
const character_anims = @import("characters_animations.zon");

// Validate at compile time
comptime {
    gfx.animation_def.validateAnimationsData(character_frames, character_anims);
}
```

### Components

- `Position` - x, y coordinates (from zig-utils Vector2)
- `Sprite` - Static sprite (name, z_index, tint, scale, rotation, flip)
- `Animation(T)` - Animated sprite with config-based enum
- `Render` - Legacy render component (sprite_name, z_index, etc.)

### Z-Index Layers

Use predefined z-index constants for proper draw order:

```zig
gfx.ZIndex.background  // 0
gfx.ZIndex.floor       // 10
gfx.ZIndex.items       // 30
gfx.ZIndex.characters  // 40
gfx.ZIndex.effects     // 50
gfx.ZIndex.ui          // 70
```

### Logging

Scoped logging following the labelle-toolkit pattern:

```zig
const gfx = @import("labelle");

// Available loggers
gfx.log.engine.info("Engine initialized", .{});
gfx.log.renderer.debug("Drawing sprite", .{});
gfx.log.animation.warn("Animation not found", .{});
gfx.log.visual.err("Failed to load atlas", .{});

// Configure in your root file:
pub const std_options: std.Options = .{
    .log_level = .debug,
    .log_scope_levels = &.{
        .{ .scope = .labelle_engine, .level = .info },
        .{ .scope = .labelle_renderer, .level = .warn },
    },
};
```

## Build Commands

```bash
# Build library
zig build

# Run tests
zig build test

# Run specific example
zig build run-example-01
zig build run-example-02
# ... through run-example-12

# Run converter tool
zig build converter -- input.json -o output.zon

# Build with atlas conversion
zig build -Dconvert-atlases=true
```

## Testing

Tests use zspec (BDD-style). Test files are in `tests/`:

```zig
pub const AnimationTests = struct {
    test "advances frame after frame_duration" {
        var anim = gfx.DefaultAnimation.init(.idle);
        anim.update(0.25);
        try expect.equal(anim.frame, 1);
    }
};
```

## Examples

| Example | Description |
|---------|-------------|
| 01_basic_sprite | Basic sprite rendering |
| 02_animation | Animation system |
| 03_sprite_atlas | Sprite atlas loading |
| 04_camera | Camera pan and zoom |
| 05_ecs_rendering | ECS render systems |
| 06_effects | Visual effects |
| 07_with_fixtures | TexturePacker fixtures demo |
| 08_nested_animations | Nested animation paths |
| 09_sokol_backend | Sokol backend example |
| 10_new_engine | Self-contained engine (headless) |
| 11_visual_engine | Visual engine with rendering |
| 12_comptime_animations | Comptime animation definitions |

## Common Patterns

### Creating Animation Enums

Always include a `config()` method:

```zig
const MyAnim = enum {
    state1, state2,

    pub fn config(self: @This()) gfx.AnimConfig {
        return switch (self) {
            .state1 => .{ .frames = 4, .frame_duration = 0.1 },
            .state2 => .{ .frames = 6, .frame_duration = 0.15, .looping = false },
        };
    }
};
```

### Sprite Name Generation

Animation sprite names are auto-generated: `"prefix/variant_0001"`

```zig
var buffer: [64]u8 = undefined;
const name = anim.getSpriteName("player", &buffer);
// Returns "player/idle_0001" for frame 0 of idle animation
```

### Backend Selection

```zig
// Use default raylib backend
const gfx = @import("labelle");
var engine = gfx.Engine.init(...);

// Use custom backend
const MyGfx = gfx.withBackend(gfx.SokolBackend);
var engine = MyGfx.Engine.init(...);
```

## CI/CD

- **CI workflow**: Builds, tests, and runs examples to capture screenshots
- **Coverage workflow**: Runs test coverage
- Screenshots are generated for examples 01-12 and compared in PRs

## Important Notes

1. **Animation enums MUST have `config()` method** - This is enforced at compile time
2. **Use `play()` to switch animations** - Not `setAnimation()` (removed)
3. **Use `unpause()` not `resume()`** - `resume` is a Zig keyword
4. **Sprite names use 4-digit padding** - e.g., `idle_0001`, `walk_0012`
5. **Frame indices are 1-based in sprite names** - Frame 0 becomes `_0001`
6. **Camera auto-centers by default** - World coords = screen coords at zoom 1

## When Making Changes

1. Run `zig build test` to ensure tests pass
2. Run `zig build` to check compilation
3. Update examples if API changes
4. CI expects all 12 example screenshots to be generated
