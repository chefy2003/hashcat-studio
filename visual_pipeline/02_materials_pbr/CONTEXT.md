# Phase 02: PBR Materials & Shaders Contract

## Role
Owns physical surface materials (slate/wet carbon floor, chassis metal, optical dielectric elements) and spatial shaders.

## Inputs
- PBR textures / procedural math
- Shaders in `shaders/` and `visual_pipeline/02_materials_pbr/`

## Process
1. Replaces flat unshaded floor with `cyber_industrial_floor.gdshader`:
   - Dual-zone roughness (wet puddles / high-polish lanes vs matte industrial plates).
   - Metallic reflection response with micro-bump normal mapping.
   - Emissive circuit traces with energy multiplier > 2.5 for SSR and SSIL interaction.
2. Creates anodized chassis and brushed aluminum PBR materials for server racks and bulkheads.

## Outputs
- `cyber_industrial_floor.gdshader`
- `server_chassis_pbr.tres`

## Human Check
- Do the holographic screen and server LEDs reflect crisply yet realistically on the floor?
- Does the floor react dynamically to moving spotlights and camera angles?
