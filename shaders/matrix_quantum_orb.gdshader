shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

// Levitating 3D "Shoal-like" Matrix Particle Swarm Shader
// Organic murmuration & shoaling swarm of thousands of glowing particles,
// flowing in coordinated undulating wave-like currents with Curl Noise turbulence,
// digital teal, neon cyan, and sudden fiery amber/gold ignitions on dense tracks.

uniform vec4 teal_color : source_color = vec4(0.0, 0.90, 1.0, 1.0);
uniform vec4 amber_color : source_color = vec4(1.0, 0.45, 0.08, 1.0);
uniform vec4 gold_color : source_color = vec4(1.0, 0.82, 0.20, 1.0);
uniform float point_size_base : hint_range(1.0, 12.0) = 4.4;
uniform float brightness : hint_range(0.5, 5.0) = 2.0;
uniform float heat_level : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.2, 5.0) = 1.6;

varying vec3 v_pos;
varying vec4 v_col;
varying float v_speed;

// 3D Curl Noise approximation for fluid shoal turbulence
vec3 curl_noise(vec3 p, float t) {
	float s = t * 1.5;
	vec3 v;
	v.x = sin(p.y * 3.6 + s) + cos(p.z * 2.9 - s * 0.75);
	v.y = sin(p.z * 3.6 + s) + cos(p.x * 2.9 - s * 0.75);
	v.z = sin(p.x * 3.6 + s) + cos(p.y * 2.9 - s * 0.75);
	return v * 0.5;
}

void vertex() {
	v_pos = VERTEX;
	v_col = COLOR;
	v_speed = UV.y;

	float stream_u = UV.x;
	float speed_mult = max(0.5, UV.y);
	float flow_t = TIME * (pulse_speed * 1.2 * speed_mult);

	// Coordinated wave-like currents & 3D Curl Noise perturbation
	vec3 curl = curl_noise(VERTEX * 2.4, flow_t);
	float turbulence = 0.020 + heat_level * 0.048;
	VERTEX += curl * turbulence;

	// Undulating murmuration expansion/contraction waves
	float shoal_wave = sin(flow_t * 2.8 + stream_u * 6.28 + VERTEX.y * 4.0) * (0.016 + heat_level * 0.022);
	VERTEX += NORMAL * shoal_wave;

	// Dynamic motion-blur streak size
	POINT_SIZE = point_size_base + sin(flow_t * 3.0 + stream_u * 12.0) * 0.8 + (heat_level * 1.6);
}

void fragment() {
	// Crisp starlight pinpoint with soft ethereal halo
	vec2 coord = POINT_COORD - vec2(0.5);
	float dist = length(coord);
	if (dist > 0.5) {
		discard;
	}
	float alpha = smoothstep(0.48, 0.06, dist);

	// Shimmering photon flicker
	float shimmer = sin(TIME * (4.2 + pulse_speed * 2.2) + v_pos.y * 16.0 + v_pos.z * 11.0) * 0.22 + 0.88;

	// Color baseline from vertex
	vec3 col = v_col.rgb;

	// Fiery amber/gold ignition where shoal condenses or accelerates
	float vortex_ignition = sin(v_pos.y * 14.0 + TIME * (3.5 + pulse_speed)) * 0.5 + 0.5;
	if (v_speed > 1.1 || heat_level > 0.08) {
		vec3 fire_col = mix(amber_color.rgb, gold_color.rgb, vortex_ignition);
		col = mix(col, fire_col, vortex_ignition * (0.35 + heat_level * 0.55));
	}

	ALBEDO = col * alpha * shimmer * brightness;
}
