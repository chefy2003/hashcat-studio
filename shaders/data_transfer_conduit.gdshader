shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// AAA Cyber High-Speed Optical Data Transfer Bus
// Visualizes discrete data packets, file blocks, and bitstreams streaming between nodes.

uniform vec4 base_casing_color : source_color = vec4(0.015, 0.02, 0.035, 1.0);
uniform vec4 data_packet_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform vec4 burst_packet_color : source_color = vec4(1.0, 0.72, 0.12, 1.0);

uniform float activity_level : hint_range(0.0, 2.0) = 0.0; // 0=idle, 1=burst, 2=streaming
uniform float packet_speed : hint_range(0.5, 30.0) = 4.0;
uniform float packet_density : hint_range(1.0, 40.0) = 12.0;
uniform float glow_intensity : hint_range(0.5, 10.0) = 3.5;

void fragment() {
	float dist_from_center = abs(UV.x - 0.5) * 2.0; // 0 at center, 1 at edges

	vec3 casing_albedo = base_casing_color.rgb;
	vec3 emissive = vec3(0.0);
	float roughness = 0.3;
	float metallic_val = 0.92;

	// Center optical core ribbon (|UV.x - 0.5| < 0.35)
	if (dist_from_center < 0.6) {
		float core_mask = 1.0 - smoothstep(0.0, 0.6, dist_from_center);

		// Multi-track binary bitstream simulation
		float speed = packet_speed * (1.0 + activity_level * 2.2);
		float lane_offset = floor(UV.x * 4.0) * 0.25;
		float packet_coord = (UV.y * packet_density) - (TIME * speed) + lane_offset;

		// Discrete rectangular/segmented data packets
		float packet_shape = fract(packet_coord);
		float packet = step(0.55, packet_shape);

		// High frequency micro-bits inside packets
		float micro_bit = step(0.3, fract(packet_coord * 4.0));
		packet *= (0.6 + micro_bit * 0.4);

		// Blend color based on activity: Idle (faint cyan) -> Burst (amber/gold) -> Streaming (electric cyan)
		vec3 color = data_packet_color.rgb;
		if (activity_level > 0.5 && activity_level < 1.5) {
			color = mix(data_packet_color.rgb, burst_packet_color.rgb, activity_level);
		} else if (activity_level >= 1.5) {
			color = mix(data_packet_color.rgb, vec3(0.3, 0.7, 1.0), activity_level - 1.0);
		}

		float base_brightness = 0.25 + activity_level * 0.8;
		float brightness = (base_brightness + packet * 1.8) * core_mask * glow_intensity;
		emissive = color * brightness;
		roughness = 0.08;
	} else {
		// Outer guide rails
		float rail = smoothstep(0.85, 0.98, dist_from_center);
		vec3 rail_color = mix(data_packet_color.rgb, burst_packet_color.rgb, clamp(activity_level, 0.0, 1.0));
		emissive = rail_color * rail * (0.8 + activity_level * 0.6);
	}

	ALBEDO = casing_albedo;
	METALLIC = metallic_val;
	ROUGHNESS = roughness;
	SPECULAR = 0.9;
	EMISSION = emissive;
}
