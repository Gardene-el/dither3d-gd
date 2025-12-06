@tool
extends Node

class_name Dither3DGlobalProperties

enum DitherColorMode { Grayscale, RGB, CMYK }

@export_group("Global Options")
@export var color_mode: DitherColorMode = DitherColorMode.RGB:
	set(value):
		color_mode = value
		update_global_options()

@export var inverse_dots: bool = false:
	set(value):
		inverse_dots = value
		update_global_options()

@export var radial_compensation: bool = false:
	set(value):
		radial_compensation = value
		update_global_options()

@export var quantize_layers: bool = false:
	set(value):
		quantize_layers = value
		update_global_options()

@export var debug_fractal: bool = false:
	set(value):
		debug_fractal = value
		update_global_options()

@export_group("Global Overrides")
@export var apply_overrides: bool = false

@export var input_exposure: float = 1.0
@export var override_input_exposure: bool = false

@export var input_offset: float = 0.0
@export var override_input_offset: bool = false

@export var dot_scale: float = 5.0
@export var override_dot_scale: bool = false

@export var size_variability: float = 0.0
@export var override_size_variability: bool = false

@export var contrast: float = 1.0
@export var override_contrast: bool = false

@export var stretch_smoothness: float = 1.0
@export var override_stretch_smoothness: bool = false

@export_group("Dots Scaling Behavior")
@export var scale_with_screen: bool = true
@export var reference_res: int = 1080

@export_group("Actions")
@export var update_now: bool = false:
	set(value):
		if value:
			apply_settings_to_scene()
		update_now = false

func _ready():
	if not Engine.is_editor_hint():
		apply_settings_to_scene()
		get_tree().root.size_changed.connect(apply_settings_to_scene)

func update_global_options():
	# In Unity, this enables keywords. In Godot, we set uniforms.
	# We need to find materials and set the 'dither_mode', 'inverse_dots', etc.
	if apply_overrides or Engine.is_editor_hint():
		apply_settings_to_scene()

func apply_settings_to_scene():
	var root = get_tree().root
	_process_node(root)

func _process_node(node: Node):
	if node is MeshInstance3D:
		_process_material(node.material_override)
		_process_material(node.material_overlay)
		var mesh = node.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				_process_material(mesh.surface_get_material(i))
				_process_material(node.get_surface_override_material(i))
	
	# Handle other node types like CSG, Particles
	if node is CSGShape3D:
		_process_material(node.material)
		_process_material(node.material_override)
	
	if node is GPUParticles3D or node is CPUParticles3D:
		_process_material(node.material_override)
		# Particles usually have draw passes with materials
		if node is GPUParticles3D:
			for i in range(node.draw_passes):
				var mesh = node.get_draw_pass_mesh(i)
				if mesh:
					for j in range(mesh.get_surface_count()):
						_process_material(mesh.surface_get_material(j))

	for child in node.get_children():
		_process_node(child)

func _process_material(mat: Material):
	if mat is ShaderMaterial:
		# Check if it's a Dither3D shader
		# We can check if it has specific params
		var shader = mat.shader
		if shader:
			# We can't easily check shader name, but we can check params
			# Or we assume if it has "dither_tex" it is one.
			var param_list = shader.get_shader_uniform_list()
			var has_dither = false
			for p in param_list:
				if p.name == "dither_tex":
					has_dither = true
					break
			
			if has_dither:
				_apply_to_material(mat)

func _apply_to_material(mat: ShaderMaterial):
	# Global Options
	mat.set_shader_parameter("dither_mode", int(color_mode))
	mat.set_shader_parameter("inverse_dots", inverse_dots)
	mat.set_shader_parameter("radial_compensation", radial_compensation)
	mat.set_shader_parameter("quantize_layers", quantize_layers)
	mat.set_shader_parameter("debug_fractal", debug_fractal)
	
	# Global Overrides
	if override_input_exposure:
		mat.set_shader_parameter("input_exposure", input_exposure)
	if override_input_offset:
		mat.set_shader_parameter("input_offset", input_offset)
	if override_dot_scale:
		var final_scale = dot_scale
		if scale_with_screen:
			var viewport_height = get_viewport().get_visible_rect().size.y
			# In Editor, get_viewport() might return the editor viewport or the main window.
			# If running in editor, we might want to use a fixed value or try to get the 3D view size.
			# But for simplicity, let's use the viewport size.
			var multiplier = float(viewport_height) / float(reference_res)
			if multiplier > 0.0:
				var log_delta = log(multiplier) / log(2.0)
				final_scale += log_delta
		
		mat.set_shader_parameter("dot_scale", final_scale)
	if override_size_variability:
		mat.set_shader_parameter("size_variability", size_variability)
	if override_contrast:
		mat.set_shader_parameter("contrast", contrast)
	if override_stretch_smoothness:
		mat.set_shader_parameter("stretch_smoothness", stretch_smoothness)
