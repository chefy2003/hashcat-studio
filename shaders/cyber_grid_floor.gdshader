shader_type spatial;
render_mode unshaded, blend_mix;

uniform vec4 grid_color : source_color = vec4(0.062, 0.85, 0.58, 1.0); // Neon Emerald #10b981
uniform vec4 bg_color : source_color = vec4(0.027, 0.035, 0.055, 1.0);   // Obsidian #07090e
uniform float grid_scale : hint_range(0.5, 100.0) = 36.0;
uniform float line_thickness : hint_range(0.5, 4.0) = 1.3;
uniform float glow_halo_width : hint_range(1.0, 10.0) = 4.5;
uniform float fade_distance : hint_range(5.0, 100.0) = 28.0;

void fragment() {
	vec2 coord = UV * grid_scale;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line_dist = min(grid.x, grid.y);

	// Crisp neon core
	float line_core = 1.0 - clamp(line_dist / line_thickness, 0.0, 1.0);
	// Soft discrete neon glow halo spreading into the dark floor
	float line_halo = 1.0 - clamp(line_dist / (line_thickness * glow_halo_width), 0.0, 1.0);
	line_halo = pow(line_halo, 2.2);

	// Distance fade towards horizon
	float dist = length(VERTEX);
	float fade = clamp(1.0 - (dist / fade_distance), 0.0, 1.0);
	fade = pow(fade, 1.3);

	// Discrete neon luminescence
	vec3 neon_aura = grid_color.rgb * (line_core * 1.5 + line_halo * 0.75);
	vec3 col = bg_color.rgb + neon_aura * fade;

	ALBEDO = col;
	ALPHA = 1.0;
}
