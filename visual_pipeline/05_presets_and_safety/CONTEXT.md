# Phase 05: Presets & Safety Contract

## Role
Guarantees rock-solid stability, crash protection, and hardware safety during intense compute operations.

## Inputs
- System configuration, environment variables, Vulkan driver state

## Process
1. `GraphicsPresetManager`:
   - Ultra AAA Preset: Forward+, SSR enabled (64 steps), SSAO enabled, SSIL enabled, Volumetric Fog enabled, ACES Tonemapping.
   - High Preset: Forward+, SSR (32 steps), SSAO enabled, Volumetric Fog low density.
   - Safe Fallback: OpenGL3 Compatibility without crashing if non-Vulkan driver detected.
2. VRAM & Compute Isolation:
   - Primary display runs on Device #0, protecting the 4x Instinct MI25 compute cards from GUI memory pressure.
   - VSync and framerate capping (60/120 FPS).
3. Core Dump Guard:
   - Enforce `ulimit -c 0` to prevent multi-gigabyte disk dumps during synthetic driver panics.

## Outputs
- `graphics_preset_manager.gd`

## Human Check
- Can user toggle between visual presets smoothly?
- Does Hashcat cracking run at maximum speed without GUI stutter?
