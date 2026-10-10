shader_type spatial;
render_mode unshaded;

// Thermal color spectrum: Blue at base -> Yellow/Amber mid -> Ruby Red at peak
uniform vec4 color_bottom : source_color = vec4(0.0, 0.42, 1.0, 1.0);  // Deep Electric Blue
uniform vec4 color_mid : source_color = vec4(1.0, 0.84, 0.0, 1.0);     // Vibrant Golden Yellow
uniform vec4 color_peak : source_color = vec4(1.0, 0.02, 0.22, 1.0);   // Blazing Ruby Red

uniform float emission_energy : hint_range(0.5, 4.0) = 1.55;
uniform float max_spectrum_height : hint_range(0.5, 3.0) = 1.35;
uniform float peak_split : hint_range(0.2, 0.8) = 0.38;

varying float v_norm_height;

void vertex() {
	// Calculate absolute elevation above visualizer base in meters
	float height_above_base = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - NODE_POSITION_WORLD.y;
	v_norm_height = clamp(height_above_base / max_spectrum_height, 0.0, 1.0);
}

void fragment() {
	vec3 bar_color;
	if (v_norm_height < peak_split) {
		float t = v_norm_height / peak_split;
		// Smooth progression from Electric Blue to Golden Yellow
		bar_color = mix(color_bottom.rgb, color_mid.rgb, smoothstep(0.0, 1.0, t));
	} else {
		float t = (v_norm_height - peak_split) / (1.0 - peak_split);
		// Smooth progression from Golden Yellow to Incandescent Ruby Red
		bar_color = mix(color_mid.rgb, color_peak.rgb, smoothstep(0.0, 1.0, t));
	}

	ALBEDO = bar_color;
	EMISSION = bar_color * emission_energy;
}
