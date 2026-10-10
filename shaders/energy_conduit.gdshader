shader_type spatial;
render_mode unshaded;

uniform vec4 base_casing_color : source_color = vec4(0.04, 0.07, 0.12, 1.0);
uniform vec4 conduit_glow_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform vec4 conduit_heat_color : source_color = vec4(1.0, 0.05, 0.25, 1.0);

uniform float heat_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.5, 15.0) = 3.5;
uniform float pulse_density : hint_range(1.0, 20.0) = 6.0;
uniform float glow_intensity : hint_range(0.5, 5.0) = 2.2;

void fragment() {
	// UV.x across conduit width (0 to 1), UV.y along conduit length
	float dist_from_center = abs(UV.x - 0.5) * 2.0; // 0 at center line, 1 at edge

	// Outer dark metallic casing with subtle bevel
	vec3 col = base_casing_color.rgb;

	// Core illuminated channel in center (|UV.x - 0.5| < 0.25)
	if (dist_from_center < 0.45) {
		float core_intensity = 1.0 - smoothstep(0.0, 0.45, dist_from_center);
		
		// Animated traveling energy pulses along length
		float wave = sin((UV.y * pulse_density) - (TIME * pulse_speed)) * 0.5 + 0.5;
		wave = pow(wave, 3.0); // Sharpen into distinct discrete energy packets
		
		// Color shifts from cyan to fiery ruby as heat increases
		vec3 active_glow = mix(conduit_glow_color.rgb, conduit_heat_color.rgb, heat_amount);
		
		float brightness = (0.35 + wave * 0.9) * core_intensity * glow_intensity;
		col = active_glow * brightness;
		
		ALBEDO = col;
		EMISSION = col;
	} else {
		// Subtle neon side rail pins
		float edge_rail = smoothstep(0.85, 0.95, dist_from_center);
		vec3 rail_col = mix(conduit_glow_color.rgb, conduit_heat_color.rgb, heat_amount) * 0.5;
		ALBEDO = mix(base_casing_color.rgb, rail_col, edge_rail);
		EMISSION = rail_col * edge_rail;
	}
}
