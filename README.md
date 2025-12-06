# Surface-Stable Fractal Dithering for Godot

This project is a port of [Dither3D](https://github.com/runevision/Dither3D) to Godot Engine, packaged as a plugin.

<img width="2992" height="1345" alt="4c71ec9d76669ef614f65f360eca6170" src="https://github.com/user-attachments/assets/1ad14628-e381-4fbf-9aac-5b550c3a5a5c" />

_The image above demonstrates the plugin in action, featuring character models from [namekuji1337](https://namekuji1337.booth.pm/items/5613012) and environment assets from [Modular Roads](https://atomicrealm.itch.io/modular-roads)._

## Features

- **Surface-Stable Fractal Dithering**: Dots stick to surfaces and maintain constant screen size.
- **Multiple Shaders**:
  - `Dither3DOpaque.gdshader`: Standard opaque material.
  - `Dither3DCutout.gdshader`: Alpha cutout support.
  - `Dither3DParticleAdd.gdshader`: Additive particles.
  - `Dither3DSkybox.gdshader`: Skybox shader (6-sided texture support).
- **Ready-to-use Materials**:
  - `materials/dither3d-opaque-default.tres`: A pre-configured material using the opaque shader. You can drop this directly onto your geometry to see the effect immediately.
- **Texture Generator**: Generate required 3D textures within the editor.

## License

This project (the Godot plugin port) is licensed under the **GNU General Public License v3.0 (GPLv3)**.

However, the core Dither3D implementation (shaders and algorithm logic) is ported from [Dither3D](https://github.com/runevision/Dither3D) by Rune Skovbo Johansen, which is licensed under the **Mozilla Public License v2.0 (MPL-2.0)**.

- The original MPL-2.0 licensed files retain their original license.
- The new files created for this Godot plugin structure are licensed under GPLv3.
- The combined work is distributed under GPLv3 in accordance with MPL-2.0 Section 3.3.
