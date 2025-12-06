@tool
extends Node

const TEXTURES_PATH = "res://addons/dither3d/textures"

@export_group("Generate Textures")
@export var generate_1x1: bool = false:
	set(value):
		if value: create_dither_3d_texture(0)
		generate_1x1 = false

@export var generate_2x2: bool = false:
	set(value):
		if value: create_dither_3d_texture(1)
		generate_2x2 = false

@export var generate_4x4: bool = false:
	set(value):
		if value: create_dither_3d_texture(2)
		generate_4x4 = false

@export var generate_8x8: bool = false:
	set(value):
		if value: create_dither_3d_texture(3)
		generate_8x8 = false

@export var generate_16x16: bool = false:
	set(value):
		if value: create_dither_3d_texture(4)
		generate_16x16 = false

@export var generate_32x32_SLOW: bool = false:
	set(value):
		if value: 
			print("Warning: Generating 32x32 texture (512x512x1024) will take a long time and use ~256MB memory.")
			create_dither_3d_texture(5)
		generate_32x32_SLOW = false

@export var generate_64x64_VERY_SLOW: bool = false:
	set(value):
		if value:
			print("Warning: Generating 64x64 texture (1024x1024x4096) requires ~4GB memory and may crash Godot or freeze your PC for a long time.")
			create_dither_3d_texture(6)
		generate_64x64_VERY_SLOW = false

@export_group("Batch Actions")
@export var generate_standard_set: bool = false:
	set(value):
		if value:
			generate_all_textures()
		generate_standard_set = false

func generate_all_textures():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(TEXTURES_PATH):
		dir.make_dir_recursive(TEXTURES_PATH)
	
	create_dither_3d_texture(0) # 1x1
	create_dither_3d_texture(1) # 2x2
	create_dither_3d_texture(2) # 4x4
	create_dither_3d_texture(3) # 8x8
	print("Standard Dither3D Textures Generated in ", TEXTURES_PATH)

func create_dither_3d_texture(recursion: int):
	print("Generating Dither Texture for recursion ", recursion)
	
	# Create Bayer points
	var bayer_points: Array[Vector2] = []
	bayer_points.append(Vector2(0.0, 0.0))
	bayer_points.append(Vector2(0.5, 0.5))
	bayer_points.append(Vector2(0.5, 0.0))
	bayer_points.append(Vector2(0.0, 0.5))
	
	for r in range(recursion - 1):
		var count = bayer_points.size()
		var offset = pow(0.5, r + 1)
		for i in range(1, 4):
			for j in range(count):
				bayer_points.append(bayer_points[j] + bayer_points[i] * offset)
	
	# Determine texture size
	var dots_per_side = int(round(pow(2, recursion)))
	var layers = dots_per_side * dots_per_side
	var size = 16 * dots_per_side
	
	# Create data for 3D texture
	var images: Array[Image] = []
	
	# Keep track of brightness buckets
	var bucket_count = 256
	var brightness_buckets: Array[int] = []
	brightness_buckets.resize(bucket_count)
	brightness_buckets.fill(0)
	
	var inv_res = 1.0 / size
	
	for z in range(layers):
		var dot_count = z + 1
		var dot_area = 0.5 / dot_count
		var dot_radius = sqrt(dot_area / PI)
		
		var image_data: PackedByteArray = PackedByteArray()
		image_data.resize(size * size) # R8 format
		
		for y in range(size):
			for x in range(size):
				var point = Vector2((x + 0.5) * inv_res, (y + 0.5) * inv_res)
				var dist = INF
				
				for i in range(dot_count):
					var vec = point - bayer_points[i]
					# Wrap around 0.5 domain (Bayer points are in 0-0.5 range? No, wait)
					# In C# code:
					# vec.x = Mathf.Repeat(vec.x + 0.5f, 1) - 0.5f;
					# Mathf.Repeat(t, length) is t - floor(t/length) * length.
					# So wrap to [0, 1] then shift to [-0.5, 0.5]
					
					vec.x = wrapf(vec.x + 0.5, 0.0, 1.0) - 0.5
					vec.y = wrapf(vec.y + 0.5, 0.0, 1.0) - 0.5
					
					var cur_dist = vec.length()
					dist = min(dist, cur_dist)
				
				# Normalize dist
				dist = dist / (dot_radius * 2.4)
				# Calculate value
				var val = clamp(1.0 - dist, 0.0, 1.0)
				
				# Store in image data (R8)
				var byte_val = int(val * 255)
				image_data[x + y * size] = byte_val
				
				var bucket = clamp(int(val * bucket_count), 0, bucket_count - 1)
				brightness_buckets[bucket] += 1
		
		var img = Image.create_from_data(size, size, false, Image.FORMAT_L8, image_data)
		images.append(img)

	# Create 3D Texture
	var texture_3d = ImageTexture3D.new()
	# create(format: Format, width: int, height: int, depth: int, use_mipmaps: bool, data: Array[Image])
	texture_3d.create(Image.FORMAT_L8, size, size, layers, false, images)
	
	var tex_name = "Dither3D_%dx%d.res" % [dots_per_side, dots_per_side]
	ResourceSaver.save(texture_3d, TEXTURES_PATH + "/" + tex_name)
	
	# Calculate brightness ramp
	var brightness_ramp: Array[float] = []
	brightness_ramp.resize(brightness_buckets.size() + 1)
	var sum = 0
	var pixel_count = size * size * layers
	
	for i in range(brightness_buckets.size()):
		sum += brightness_buckets[brightness_buckets.size() - 1 - i]
		brightness_ramp[i + 1] = float(sum) / float(pixel_count)
		
	# Calculate inverse brightness ramp
	var lookup_ramp: Array[float] = []
	lookup_ramp.resize(size)
	
	var lower_index_brightness = 0.0
	var higher_index = 1
	var higher_index_brightness = brightness_ramp[1]
	
	for i in range(size):
		var desired_brightness = float(i) / float(size - 1)
		while higher_index_brightness < desired_brightness:
			higher_index += 1
			if higher_index >= brightness_ramp.size():
				higher_index = brightness_ramp.size() - 1
				break
			higher_index_brightness = brightness_ramp[higher_index]
			
		# InverseLerp(a, b, value) = (value - a) / (b - a)
		var l = 0.0
		if higher_index_brightness != lower_index_brightness:
			l = (desired_brightness - lower_index_brightness) / (higher_index_brightness - lower_index_brightness)
			
		lookup_ramp[i] = (higher_index - 1 + l) / (brightness_ramp.size() - 1)
		
	create_ramp_texture("Dither3D_%dx%d_Ramp.png" % [dots_per_side, dots_per_side], lookup_ramp)

func create_ramp_texture(name: String, lookup_ramp: Array[float]):
	var width = lookup_ramp.size()
	var image_data = PackedByteArray()
	image_data.resize(width)
	
	for x in range(width):
		var val = lookup_ramp[x]
		image_data[x] = int(val * 255)
		
	var img = Image.create_from_data(width, 1, false, Image.FORMAT_L8, image_data)
	
	if name.ends_with(".png"):
		img.save_png(TEXTURES_PATH + "/" + name)
	else:
		var tex = ImageTexture.create_from_image(img)
		ResourceSaver.save(tex, TEXTURES_PATH + "/" + name)
