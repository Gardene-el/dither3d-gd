@tool
extends EditorPlugin

const DitherGeneratorScript = preload("scripts/Dither3DTextureGenerator.gd")

var _popup_menu: PopupMenu

func _enter_tree():
	add_custom_type("Dither3DGlobalProperties", "Node", preload("scripts/Dither3DGlobalProperties.gd"), preload("icon.svg"))
	
	# Create a submenu for Dither3D tools
	_popup_menu = PopupMenu.new()
	_popup_menu.add_item("Generate 1x1 (Bayer)", 0)
	_popup_menu.add_item("Generate 2x2 (Bayer)", 1)
	_popup_menu.add_item("Generate 4x4 (Bayer)", 2)
	_popup_menu.add_item("Generate 8x8 (Bayer)", 3)
	_popup_menu.add_separator()
	_popup_menu.add_item("Generate All Standard", 100)
	
	# Connect the menu item press signal
	_popup_menu.id_pressed.connect(_on_menu_item_pressed)
	
	# Add the submenu to Project > Tools
	add_tool_submenu_item("Dither3D Textures", _popup_menu)

func _exit_tree():
	remove_custom_type("Dither3DGlobalProperties")
	
	remove_tool_menu_item("Dither3D Textures")
	if _popup_menu:
		_popup_menu.queue_free()
		_popup_menu = null

func _on_menu_item_pressed(id: int):
	match id:
		0: _run_generator(0)
		1: _run_generator(1)
		2: _run_generator(2)
		3: _run_generator(3)
		100: _generate_all()

func _generate_all():
	var generator = DitherGeneratorScript.new()
	generator.generate_all_textures()
	generator.free()
	# Rescan to show new files in FileSystem dock
	get_editor_interface().get_resource_filesystem().scan()

func _run_generator(recursion: int):
	var generator = DitherGeneratorScript.new()
	generator.create_dither_3d_texture(recursion)
	generator.free()
	# Rescan to show new files in FileSystem dock
	get_editor_interface().get_resource_filesystem().scan()
