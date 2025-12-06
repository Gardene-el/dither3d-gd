shader_type sky;

uniform vec4 tint_color : source_color = vec4(0.5, 0.5, 0.5, 0.5);
uniform float exposure : hint_range(0, 8) = 1.0;
uniform float rotation : hint_range(0, 360) = 0.0;

uniform sampler2D front_tex : source_color, filter_linear;
uniform sampler2D back_tex : source_color, filter_linear;
uniform sampler2D left_tex : source_color, filter_linear;
uniform sampler2D right_tex : source_color, filter_linear;
uniform sampler2D up_tex : source_color, filter_linear;
uniform sampler2D down_tex : source_color, filter_linear;

// Dither uniforms (copied from include because we can't include easily if types mismatch or if include assumes spatial)
// Actually we can try including.
// But we need to define macros or something if we want to handle the missing PROJECTION_MATRIX.
// The include function `get_dither_3d` takes `proj_matrix` as an argument.
// So it should be fine as long as we pass a mat4.

#include "Dither3DInclude.gdshaderinc"

vec3 rotate_around_y_in_degrees(vec3 vertex, float degrees) {
	float alpha = degrees * PI / 180.0;
	float sina = sin(alpha);
	float cosa = cos(alpha);
	mat2 m = mat2(vec2(cosa, -sina), vec2(sina, cosa));
	return vec3((m * vertex.xz).x, vertex.y, (m * vertex.xz).y).xzy;
}

void sky() {
	vec3 dir = EYEDIR;
	dir = rotate_around_y_in_degrees(dir, rotation);
	
	// 6-sided mapping logic
	// This is a bit complex to replicate exactly from the Unity shader which uses standard skybox logic implicitly?
	// No, the Unity shader has `skybox_frag` which takes `texcoord` from vertex shader.
	// But it also has 6 passes, each rendering one face?
	// Godot Sky shader renders the whole sky.
	// We need to sample the correct texture based on direction.
	
	vec4 color = vec4(0.0);
	vec3 abs_dir = abs(dir);
	float max_axis = max(abs_dir.x, max(abs_dir.y, abs_dir.z));
	
	// Simple cubemap sampling logic
	// We can use a switch or if-else
	// Note: This is not efficient but matches the 6-texture input.
	// Ideally user should provide a Cubemap texture.
	
	if (abs_dir.x >= abs_dir.y && abs_dir.x >= abs_dir.z) {
		if (dir.x > 0.0) {
			// Left (+X in Unity? Unity is LHS. Godot is RHS. +X is Right in Godot?)
			// Unity: +X is Left? "Left [+X]" in shader properties.
			// Godot: +X is Right.
			// Let's assume the textures are named by direction.
			// We need to map UVs.
			vec2 uv = vec2(-dir.z, -dir.y) / abs_dir.x * 0.5 + 0.5;
			color = texture(left_tex, uv); // Unity Left
		} else {
			// Right (-X)
			vec2 uv = vec2(dir.z, -dir.y) / abs_dir.x * 0.5 + 0.5;
			color = texture(right_tex, uv); // Unity Right
		}
	} else if (abs_dir.y >= abs_dir.x && abs_dir.y >= abs_dir.z) {
		if (dir.y > 0.0) {
			// Up (+Y)
			vec2 uv = vec2(dir.x, dir.z) / abs_dir.y * 0.5 + 0.5;
			color = texture(up_tex, uv);
		} else {
			// Down (-Y)
			vec2 uv = vec2(dir.x, -dir.z) / abs_dir.y * 0.5 + 0.5;
			color = texture(down_tex, uv);
		}
	} else {
		if (dir.z > 0.0) {
			// Front (+Z)
			vec2 uv = vec2(dir.x, -dir.y) / abs_dir.z * 0.5 + 0.5;
			color = texture(front_tex, uv);
		} else {
			// Back (-Z)
			vec2 uv = vec2(-dir.x, -dir.y) / abs_dir.z * 0.5 + 0.5;
			color = texture(back_tex, uv);
		}
	}
	
	vec3 c = color.rgb * tint_color.rgb * exposure;
	
	// Dithering UV calculation from Unity shader
	// float u = atan2(-dir.z, dir.x) * 2 / UNITY_PI + 1;
	// float u2 = atan2(dir.z, -dir.x) * 2 / UNITY_PI + 1;
	// float v = acos(-dir.y) * 2 / UNITY_PI - 1;
	
	float u = atan(-dir.z, dir.x) * 2.0 / PI + 1.0;
	float u2 = atan(dir.z, -dir.x) * 2.0 / PI + 1.0;
	float v = acos(-dir.y) * 2.0 / PI - 1.0;
	
	float a = v * 0.5 * PI;
	// v = 0.731746 * log(tan(a) + 1.0 / cos(a));
	// tan(a) + 1/cos(a) = (sin(a)+1)/cos(a)
	v = 0.731746 * log((sin(a) + 1.0) / cos(a));
	
	// We don't have SCREEN_UV directly.
	// But we can pass vec2(0.0) if we don't use radial compensation.
	// Or we can try to approximate it.
	// For now, pass vec2(0.0) and identity matrix.
	
	vec2 uvA = vec2(u, v);
	vec2 uvB = vec2(u2, v);
	COLOR = get_dither_3d_color_alt_uv(uvA, uvB, vec2(0.0), c, mat4(1.0), dFdx(uvA), dFdy(uvA), dFdx(uvB), dFdy(uvB));
}
