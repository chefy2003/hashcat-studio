# Phase 03: Holographic VFX Contract

## Role
Owns diegetic user interfaces, optical holographic shaders, and volumetric projections in the 3D world.

## Inputs
- SubViewport UI render targets from `scripts/ui/3d/holo_terminal_3d.gd` and `gui_3d_panel.gd`

## Process
1. Implements `holo_diegetic_display.gdshader`:
   - Subtle geometric curvature / beveled holographic boundary.
   - Fresnel edge rim glow that highlights terminal angles.
   - Horizontal raster scanlines and micro-chromatic dispersion (RGB split at edges).
   - High-contrast text clarity (ensures HUD text remains 100% sharp and readable).
2. Upgrades quantum core holographic ring and crystal shaders (`hologram_core_rings.gdshader`).

## Outputs
- `holo_diegetic_display.gdshader`
- `holo_core_crystal.gdshader`

## Human Check
- Is console output completely legible in first-person and terminal focus modes?
- Does the terminal look like a physically emitted hologram rather than a flat billboard?
