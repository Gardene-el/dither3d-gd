@tool
extends CanvasLayer

@export_group("Monochrome Settings")
@export var dark_color: Color = Color.BLACK:
	set(value):
		dark_color = value
		_update_shader_params()

@export var light_color: Color = Color.WHITE:
	set(value):
		light_color = value
		_update_shader_params()

@export var monochrome_1bit: bool = false:
	set(value):
		monochrome_1bit = value
		_update_shader_params()

@export_range(0.0, 1.0) var threshold: float = 0.5:
	set(value):
		threshold = value
		_update_shader_params()

@onready var color_rect = $ColorRect

func _ready():
	_update_shader_params()

func _update_shader_params():
	if not is_inside_tree(): return
	
	# In tool mode or runtime, we need to find the node if onready hasn't fired yet or if we are in the editor
	if not color_rect:
		if has_node("ColorRect"):
			color_rect = $ColorRect
		else:
			return

	if color_rect.material:
		color_rect.material.set_shader_parameter("dark_color", dark_color)
		color_rect.material.set_shader_parameter("light_color", light_color)
		color_rect.material.set_shader_parameter("monochrome_1bit", monochrome_1bit)
		color_rect.material.set_shader_parameter("threshold", threshold)
