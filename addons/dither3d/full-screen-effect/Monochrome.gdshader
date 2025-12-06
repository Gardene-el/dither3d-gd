shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool monochrome_1bit = false;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	
	if (monochrome_1bit) {
		// Component-wise threshold
		color.r = step(threshold, color.r);
		color.g = step(threshold, color.g);
		color.b = step(threshold, color.b);
	}
	
	// Lerp between dark and light
	color.rgb = mix(dark_color.rgb, light_color.rgb, color.rgb);
	
	COLOR = color;
}
