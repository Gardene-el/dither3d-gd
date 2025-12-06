shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color;
uniform float roughness : hint_range(0, 1) = 0.5;
uniform float metallic : hint_range(0, 1) = 0.0;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_emission : source_color;
uniform vec4 emission : source_color = vec4(0.0);

#include "Dither3DInclude.gdshaderinc"

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	vec3 base_color = albedo.rgb * albedo_tex.rgb;
	
	// Apply Dither to Albedo
	// Note: This applies dithering to the base color, not the final lit color.
	// To dither the final lit color, one would need a post-process or unshaded material with manual lighting.
	ALBEDO = get_dither_3d_color(UV, SCREEN_UV, base_color, PROJECTION_MATRIX, dFdx(UV), dFdy(UV));
	
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = texture(texture_normal, UV).rgb;
	EMISSION = texture(texture_emission, UV).rgb * emission.rgb;
}
