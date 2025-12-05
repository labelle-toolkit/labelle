//! ECS Systems (removed)
//!
//! ECS-based systems have been removed from labelle.
//! Use VisualEngine for sprite rendering and animation management.
//!
//! The VisualEngine provides equivalent functionality without requiring
//! an external ECS library:
//!
//! ```zig
//! var engine = try gfx.VisualEngine.init(allocator, .{...});
//!
//! // Add sprites
//! const player = try engine.addSprite(.{
//!     .sprite_name = "player_idle",
//!     .x = 100, .y = 100,
//! });
//!
//! // Play animations
//! _ = engine.playAnimation(player, "walk", 6, 0.6, true);
//!
//! // Update and render
//! engine.tick(dt);
//! ```

// This file is kept for backwards compatibility but exports nothing.
// If you need ECS integration, implement it in your game code directly.
