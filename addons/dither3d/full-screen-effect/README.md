# Dither3D Fullscreen Effects

This folder contains Godot implementations of the fullscreen effects from the original Unity plugin.

## Monochrome Effect

A post-processing effect that maps the screen colors to a two-color gradient (Dark Color -> Light Color). It also supports a "1-bit" mode which thresholds colors before mapping.

**How to use:**

1. Instantiate `Dither3DMonochrome.tscn` in your scene.
2. Adjust the Shader Parameters on the `ColorRect` node inside it:
   - `dark_color`: The color for dark pixels (default Black).
   - `light_color`: The color for light pixels (default White).
   - `monochrome_1bit`: If true, colors are snapped to 0 or 1 before coloring.

## Upscale Effect

A "Sharp Bilinear" upscaling shader. This is useful when you are rendering your game at a low resolution (e.g. via a SubViewport) and want to scale it up to the window size without it looking blurry (standard bilinear) or having shimmering artifacts (nearest neighbor).

**How to use:**

1. Set up a `SubViewportContainer` and `SubViewport` for your game rendering.
2. Set the `SubViewport` size to your desired low resolution (e.g. 320x180).
3. Set the `SubViewportContainer` stretch mode to keep aspect or scale.
4. Apply a `ShaderMaterial` to the `SubViewportContainer`.
5. Assign `Upscale.gdshader` to the material.
6. **Important:** Ensure the Texture Filter on the SubViewportContainer (or the project default) allows for linear filtering, as the shader relies on it to smooth the edges.
