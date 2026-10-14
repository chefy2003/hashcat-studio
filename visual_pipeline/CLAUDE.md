# Visual Pipeline (ICM Catalog)

Modular AAA 3D graphics & rendering system for Hashcat Studio.
Built for Godot 4 Forward+ (Vulkan 1.4 Clustered) targeting Cyberpunk 2077 / Matrix Awakens visual fidelity.

## Routing

| Phase / Directory | Purpose | Primary Files |
| :--- | :--- | :--- |
| `01_environment_lighting/` | WorldEnvironment, HDR Tonemapping, SSR, SSAO, SSIL, Volumetric Fog & Spotlights | `env_ops_deck_forward_plus.tres`, `lighting_rig_3d.gd` |
| `02_materials_pbr/` | PBR Surface Shaders (Slate/wet carbon floor, metallic chassis, micro-scratches) | `cyber_industrial_floor.gdshader`, `pbr_chassis.tres` |
| `03_hologram_vfx/` | Diegetic holographic display shaders, optical refraction, Fresnel rim, scanlines | `holo_diegetic_display.gdshader`, `holo_core_crystal.gdshader` |
| `04_telemetry_vfx/` | Real-time GPU load visualizers, GPUParticles3D data dust, energy conduits | `gpu_activity_leds.gd`, `energy_conduit_vfx.gd` |
| `05_presets_and_safety/` | Quality presets (Ultra AAA / Safe Compatibility), VRAM guard & coredump shield | `graphics_preset_manager.gd` |

## Pipeline Flow
`01_env` sets up Vulkan world -> `02_materials` binds PBR shaders -> `03_holograms` projects diegetic UI -> `04_telemetry` binds Hashcat activity -> `05_presets` enforces safety and performance.
