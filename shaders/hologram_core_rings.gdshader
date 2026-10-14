shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Precision Dark Chrome Gyroscopic Gimbal Ring Shader
// Physically shaded dark metallic rings with recessed pulsing optical laser tracks.

uniform vec4 ring_metal_color : source_color = vec4(0.06, 0.09, 0.14, 1.0);
uniform vec4 core_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform float emission_energy : hint_range(0.0, 5.0) = 2.4;
uniform float segment_count : hint_range(4.0, 64.0) = 24.0;
uniform float pulse_speed : hint_range(0.1, 5.0) = 2.0;

void fragment() {
	// Laser pulse segments running around the ring circumference (UV.x wraps 0..1)
	float angle = UV.x * 6.28318530718;
	float segments = sin(angle * segment_count + TIME * pulse_speed * 1.8) * 0.5 + 0.5;
	segments = smoothstep(0.48, 0.75, segments);

	// Recessed optical laser track along the outer equator of the torus (UV.y = 0.5)
	float track = 1.0 - smoothstep(0.0, 0.22, abs(UV.y - 0.5));
	vec3 emissive = core_color.rgb * segments * track * emission_energy;

	ALBEDO = ring_metal_color.rgb;
	METALLIC = 0.94;
	ROUGHNESS = 0.20;
	SPECULAR = 0.92;
	EMISSION = emissive;
}
