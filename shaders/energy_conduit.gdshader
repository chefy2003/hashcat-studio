shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// AAA PBR Energy Conduit Shader
// Physically shaded dark metallic casing with high-intensity glowing core
// casting SSIL indirect illumination and SSR floor reflections.

uniform vec4 base_casing_color : source_color = vec4(0.02, 0.03, 0.05, 1.0);
uniform vec4 conduit_glow_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform vec4 conduit_heat_color : source_color = vec4(1.0, 0.15, 0.25, 1.0);

uniform float heat_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.5, 15.0) = 3.5;
uniform float pulse_density : hint_range(1.0, 20.0) = 6.0;
uniform float glow_intensity : hint_range(0.5, 8.0) = 3.2;

void fragment() {
	float dist_from_center = abs(UV.x - 0.5) * 2.0; // 0 at center line, 1 at edge

	vec3 casing_albedo = base_casing_color.rgb;
	vec3 emissive = vec3(0.0);
	float roughness = 0.35;
	float metallic_val = 0.88;

	// Core illuminated channel in center (|UV.x - 0.5| < 0.25)
	if (dist_from_center < 0.45) {
		float core_intensity = 1.0 - smoothstep(0.0, 0.45, dist_from_center);
		
		// Animated traveling energy pulses along length
		float wave = sin((UV.y * pulse_density) - (TIME * pulse_speed)) * 0.5 + 0.5;
		wave = pow(wave, 3.0); // Sharpen into distinct energy packets
		
		// Color shifts from cyan to fiery ruby as heat increases
		vec3 active_glow = mix(conduit_glow_color.rgb, conduit_heat_color.rgb, heat_amount);
		
		float brightness = (0.4 + wave * 1.2) * core_intensity * glow_intensity;
		emissive = active_glow * brightness;
		roughness = 0.1;
	} else {
		// Subtle neon side rail pins
		float edge_rail = smoothstep(0.85, 0.95, dist_from_center);
		vec3 rail_col = mix(conduit_glow_color.rgb, conduit_heat_color.rgb, heat_amount) * 1.5;
		emissive = rail_col * edge_rail;
	}

	ALBEDO = casing_albedo;
	METALLIC = metallic_val;
	ROUGHNESS = roughness;
	SPECULAR = 0.8;
	EMISSION = emissive;
}
