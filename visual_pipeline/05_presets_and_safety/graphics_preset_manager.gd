class_name GraphicsPresetManager
extends Node

## Graphics Preset & Safety Safeguard Manager.
## Provides runtime scalability, GPU compute isolation, and safe fallback handling.

enum QualityPreset {
	ULTRA_AAA,
	HIGH,
	COMPATIBILITY_SAFE
}

const ENV_FORWARD_PLUS = preload("res://visual_pipeline/01_environment_lighting/env_ops_deck_forward_plus.tres")

static var current_preset: QualityPreset = QualityPreset.ULTRA_AAA

static func apply_preset_to_environment(env: Environment, preset: QualityPreset) -> void:
	if env == null:
		return

	current_preset = preset

	match preset:
		QualityPreset.ULTRA_AAA:
			env.tonemap_mode = Environment.TONE_MAPPER_ACES
			env.ssr_enabled = true
			env.ssr_max_steps = 64
			env.ssao_enabled = true
			env.ssao_radius = 1.6
			env.ssao_intensity = 2.4
			env.ssil_enabled = true
			env.ssil_intensity = 1.3
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.014
			env.glow_enabled = true
			env.glow_hdr_threshold = 0.95

		QualityPreset.HIGH:
			env.tonemap_mode = Environment.TONE_MAPPER_ACES
			env.ssr_enabled = true
			env.ssr_max_steps = 32
			env.ssao_enabled = true
			env.ssao_radius = 1.4
			env.ssao_intensity = 1.8
			env.ssil_enabled = false
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.010
			env.glow_enabled = true
			env.glow_hdr_threshold = 1.0

		QualityPreset.COMPATIBILITY_SAFE:
			env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			env.ssr_enabled = false
			env.ssao_enabled = false
			env.ssil_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = true
			env.glow_hdr_threshold = 1.1

static func is_vulkan_forward_plus() -> bool:
	var method = ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus")
	return method == "forward_plus"
