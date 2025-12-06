shader_type canvas_item;

// This shader is intended to be used on a TextureRect or SubViewportContainer
// that is displaying a low-resolution texture scaled up to a high-resolution screen.
// It performs "Sharp Bilinear" filtering.

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 pixel_size = 1.0 / tex_size;
	
	vec2 uv = UV;
	
	// Shift by half a pixel so UV is (0, 0) half a texel from the screen corner.
	uv -= pixel_size * 0.5;
	
	// Get texel coordinates that are integers at the center of each texel.
	vec2 uv_pixels = uv * tex_size;
	
	// Get vector with coordinates that are 0 at texel corners 
	// and flip from 0.5 to -0.5 at texel centers.
	vec2 texel_border_gradient = fract(uv_pixels) - 0.5;
	
	vec2 texel_size_deriv = fwidth(uv_pixels);
	// Avoid division by zero
	texel_size_deriv = max(texel_size_deriv, vec2(0.00001));
	
	vec2 val = clamp(texel_border_gradient / texel_size_deriv, 0.0, 1.0);
	vec2 sample_offset = (val - texel_border_gradient);

	vec2 clampedUV = uv + sample_offset * pixel_size;
	
	COLOR = textureLod(TEXTURE, clampedUV, 0.0);
}
