@tool
extends Control

@export_group("Retro Resolution")
@export var internal_resolution: Vector2i = Vector2i(320, 240):
	set(value):
		internal_resolution = value
		_update_viewport_size()

@export_group("Upscale Effect")
@export var enable_upscale: bool = true:
	set(value):
		enable_upscale = value
		_update_material()

const UPSCALE_SHADER = preload("res://addons/dither3d/full-screen-effect/Upscale.gdshader")

func _ready():
	# Configure TextureRect
	var tex_rect = _get_texture_rect()
	if tex_rect:
		tex_rect.texture_filter = TEXTURE_FILTER_LINEAR
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.anchors_preset = Control.PRESET_FULL_RECT
	
	# Configure Viewport
	var vp = _get_sub_viewport()
	if vp:
		vp.size = internal_resolution
		vp.handle_input_locally = true # We will forward input manually
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		# Link Viewport Texture to TextureRect
		if tex_rect:
			tex_rect.texture = vp.get_texture()
	
	_update_material()

func _get_texture_rect() -> TextureRect:
	if has_node("ViewportDisplay"):
		return $ViewportDisplay as TextureRect
	return null

func _get_sub_viewport() -> SubViewport:
	if has_node("SubViewport"):
		return $SubViewport as SubViewport
	return null

func _update_viewport_size():
	var vp = _get_sub_viewport()
	if vp:
		vp.size = internal_resolution

func _update_material():
	var tex_rect = _get_texture_rect()
	if not tex_rect: return
	
	if enable_upscale:
		if not tex_rect.material:
			tex_rect.material = ShaderMaterial.new()
		
		if tex_rect.material is ShaderMaterial:
			if (tex_rect.material as ShaderMaterial).shader != UPSCALE_SHADER:
				(tex_rect.material as ShaderMaterial).shader = UPSCALE_SHADER
	else:
		tex_rect.material = null

# Forward Input to SubViewport
func _unhandled_input(event):
	var vp = _get_sub_viewport()
	if vp:
		vp.push_input(event)
