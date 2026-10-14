shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// AAA Architectural Industrial Floor Shader
// Realistic dark wet carbon slate with recessed mechanical seams,
// discrete high-tech runway guide lights, and mirror-like Screen-Space Reflections (SSR).

group_uniforms BaseProperties;
uniform vec4 base_albedo : source_color = vec4(0.010, 0.014, 0.020, 1.0);     // Inky dark slate
uniform vec4 plate_albedo : source_color = vec4(0.018, 0.025, 0.035, 1.0);    // Anodized heavy structural slab
uniform float metallic : hint_range(0.0, 1.0) = 0.92;
uniform float rough_polished : hint_range(0.0, 1.0) = 0.06;                   // Wet mirror reflection (SSR)
uniform float rough_matte : hint_range(0.0, 1.0) = 0.32;                      // Fine brushed slab texture
uniform float tile_scale : hint_range(1.0, 60.0) = 14.0;

group_uniforms CircuitEmission;
uniform vec4 circuit_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);        // Precision Cyan
uniform vec4 circuit_accent : source_color = vec4(0.062, 0.85, 0.58, 1.0);     // Cyber Emerald
uniform float emission_energy : hint_range(0.0, 10.0) = 1.8;
uniform float line_thickness : hint_range(0.005, 0.1) = 0.018;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;

group_uniforms SurfaceDetail;
uniform float normal_depth : hint_range(0.0, 2.0) = 0.85;
uniform float bevel_width : hint_range(0.01, 0.2) = 0.045;
uniform float fade_distance : hint_range(10.0, 150.0) = 80.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv_scaled = UV * tile_scale;
	vec2 grid_uv = fract(uv_scaled);
	vec2 cell_id = floor(uv_scaled);

	// Distance to tile edges
	vec2 edge_dist = min(grid_uv, 1.0 - grid_uv);
	float min_edge = min(edge_dist.x, edge_dist.y);

	// Beveled groove around structural slabs
	float groove = 1.0 - smoothstep(0.0, bevel_width, min_edge);
	
	// Micro-brushing noise for realistic anisotropic reflection glints
	float micro_brushed = noise(uv_scaled * vec2(20.0, 3.5)) * 0.08;
	float micro_scratches = noise(uv_scaled * 35.0) * 0.05;

	// Checkered alternating slab finish (matte vs high polish)
	float checker = mod(cell_id.x + cell_id.y, 2.0);
	float tile_roughness = mix(rough_polished, rough_matte, checker * 0.55) + micro_brushed;
	tile_roughness = mix(tile_roughness, 0.70, groove);

	// Albedo: inky dark tones with realistic micro-variations
	vec3 surface_color = mix(plate_albedo.rgb, base_albedo.rgb, checker * 0.35);
	surface_color = mix(surface_color, vec3(0.005, 0.007, 0.010), groove);
	surface_color += (micro_scratches - 0.025) * 0.10;

	// Runway guide lights: only illuminate arterial structural seams (every 3rd slab or along center aisles)
	bool is_arterial = (mod(cell_id.x, 3.0) == 0.0 && edge_dist.y < line_thickness) ||
	                   (mod(cell_id.y, 3.0) == 0.0 && edge_dist.x < line_thickness) ||
	                   (abs(cell_id.x) <= 1.0 && edge_dist.x < line_thickness);

	float circuit_mask = 0.0;
	if (is_arterial) {
		circuit_mask = 1.0 - smoothstep(0.0, line_thickness, min_edge);
	}
	
	// Subtle pulse packet traveling along runway lanes
	float wave = sin((cell_id.x + cell_id.y) * 0.6 - TIME * pulse_speed) * 0.5 + 0.5;
	vec3 current_circuit_col = mix(circuit_color.rgb, circuit_accent.rgb, wave * 0.5);
	vec3 emissive = current_circuit_col * circuit_mask * (emission_energy + pow(wave, 4.0) * 1.2);

	// Distance fade for seamless edge blending
	float cam_dist = length(VERTEX);
	float fade = clamp(1.0 - (cam_dist / fade_distance), 0.0, 1.0);
	fade = pow(fade, 1.4);
	emissive *= fade;

	// Beveled edge normals
	vec2 normal_offset = (vec2(0.5) - grid_uv) * groove * normal_depth;
	vec3 proc_normal = normalize(vec3(normal_offset.x, normal_offset.y, 1.0));

	ALBEDO = surface_color;
	METALLIC = metallic * (1.0 - groove * 0.35);
	ROUGHNESS = clamp(tile_roughness, 0.04, 0.95);
	NORMAL = (VIEW_MATRIX * vec4(NORMAL.xy + proc_normal.xy, NORMAL.z, 0.0)).xyz;
	EMISSION = emissive;
	SPECULAR = 0.88;
}
