# Phase 01: Environment & Lighting Contract

## Role
Owns the physical atmosphere, camera attributes, tone mapping, and volumetric light scattering in the 3D Operations Arena.

## Inputs
- Engine renderer: Forward+ (Vulkan 1.4)
- Scene node: `scenes/dashboard_3d.tscn` -> `WorldEnvironment`

## Process
1. Configures ACES tonemapper with high dynamic range bloom knee.
2. Enables Screen-Space Reflections (SSR) with high raymarching precision.
3. Enables Screen-Space Ambient Occlusion (SSAO) for grounded contact shadows.
4. Enables Screen-Space Indirect Lighting (SSIL) for neon color bounce.
5. Enables Volumetric Fog with scattering and temporal reprojection.
6. Deploys overhead gantry spot lights with shadow casting and volumetric fog energy.

## Outputs
- `env_ops_deck_forward_plus.tres` (Environment resource)
- `lighting_rig_3d.gd` (Cinematic light rig controller)

## Human Check
- Are contact shadows visible under server racks and pillars?
- Do overhead spotlights produce visible light cones through the atmospheric fog?
- Is contrast deep without crushed blacks or clipped whites?
