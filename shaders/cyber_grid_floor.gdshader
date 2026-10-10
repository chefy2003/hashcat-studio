shader_type spatial;
render_mode unshaded, blend_mix;

uniform vec4 grid_color : source_color = vec4(0.062, 0.725, 0.505, 1.0); // Emerald #10b981
uniform vec4 bg_color : source_color = vec4(0.027, 0.035, 0.055, 1.0);   // Obsidian #07090e
uniform float grid_scale : hint_range(0.5, 100.0) = 40.0;
uniform float line_thickness : hint_range(0.5, 4.0) = 1.2;
uniform float fade_distance : hint_range(5.0, 100.0) = 24.0;

void fragment() {
	vec2 coord = UV * grid_scale;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = min(grid.x, grid.y);
	float line_intensity = 1.0 - clamp(line / line_thickness, 0.0, 1.0);

	// Distance fade to horizon
	float dist = length(VERTEX);
	float fade = clamp(1.0 - (dist / fade_distance), 0.0, 1.0);
	fade = pow(fade, 1.5);

	vec3 col = mix(bg_color.rgb, grid_color.rgb * 1.3, line_intensity);
	ALBEDO = col;
	ALPHA = fade;
}
