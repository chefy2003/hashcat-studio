shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 core_color : source_color = vec4(0.0, 0.94, 1.0, 1.0); // Cyan #00f0ff
uniform float fresnel_power : hint_range(1.0, 8.0) = 2.2;
uniform float pulse_speed : hint_range(0.1, 5.0) = 2.5;
uniform float segment_count : hint_range(4.0, 64.0) = 16.0;
uniform float glow_intensity : hint_range(0.5, 4.0) = 1.15;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	float pulse = sin(TIME * pulse_speed) * 0.15 + 0.85;

	// Segmented ring dashed effect
	float angle = atan(UV.y - 0.5, UV.x - 0.5);
	float segments = sin(angle * segment_count + TIME * 1.5) * 0.5 + 0.5;
	segments = step(0.25, segments);

	vec3 col = core_color.rgb * (fresnel * 0.65 + 0.4) * pulse * glow_intensity;
	ALBEDO = col;
	ALPHA = clamp((fresnel * 0.85 + 0.25) * segments, 0.0, 1.0);
}
