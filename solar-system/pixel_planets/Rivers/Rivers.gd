extends "res://pixel_planets/Planet.gd"

# Store base colors so we can shift them relative to their original hue
var base_land_colors: Array = []
var base_river_colors: Array = []
var base_cloud_colors: Array = []

var current_hue_offset: float = 0.0
var land_hue_offset: float = 0.0
var river_hue_offset: float = 0.0
var cloud_hue_offset: float = 0.0

func _ready():
	# Store initial base colors on start
	_save_base_colors()

func _save_base_colors():
	var current = get_colors()
	base_land_colors = current.slice(0, 4)
	base_river_colors = current.slice(4, 6)
	base_cloud_colors = current.slice(6, 10)

# Shift all colors along the HSV hue spectrum by hue_offset (0.0 to 1.0)
func shift_planet_hue(hue_offset: float) -> void:
	current_hue_offset = hue_offset
	var shifted_land = _shift_color_array(base_land_colors, hue_offset)
	var shifted_rivers = _shift_color_array(base_river_colors, hue_offset)
	var shifted_clouds = _shift_color_array(base_cloud_colors, hue_offset)

	set_colors(shifted_land + shifted_rivers + shifted_clouds)

func shift_planet_land_hue(hue_offset: float) -> void:
	land_hue_offset = hue_offset
	_update_hues()

func shift_planet_rivers_hue(hue_offset: float) -> void:
	river_hue_offset = hue_offset
	_update_hues()

func shift_planet_cloud_hue(hue_offset: float) -> void:
	cloud_hue_offset = hue_offset
	_update_hues()

func _update_hues() -> void:
	var shifted_land = _shift_color_array(
		base_land_colors,
		land_hue_offset
	)

	var shifted_rivers = _shift_color_array(
		base_river_colors,
		river_hue_offset
	)

	var shifted_clouds = _shift_color_array(
		base_cloud_colors,
		cloud_hue_offset
	)

	set_colors(shifted_land + shifted_rivers + shifted_clouds)

func get_land_hue() -> float:
	return land_hue_offset


func get_river_hue() -> float:
	return river_hue_offset


func get_cloud_hue() -> float:
	return cloud_hue_offset

func _shift_color_array(color_array: Array, hue_offset: float) -> Array:
	var new_colors = []

	for col in color_array:
		var new_h = fmod(col.h + hue_offset, 1.0)

		if new_h < 0.0:
			new_h += 1.0

		new_colors.append(
			Color.from_hsv(
				new_h,
				col.s,
				col.v,
				col.a
			)
		)

	return new_colors

func set_pixels(amount):
	$Land.material.set_shader_parameter("pixels", amount)
	$Cloud.material.set_shader_parameter("pixels", amount)
	$Land.size = Vector2(amount, amount)
	$Cloud.size = Vector2(amount, amount)

func set_light(pos):
	$Cloud.material.set_shader_parameter("light_origin", pos)
	$Land.material.set_shader_parameter("light_origin", pos)

func set_seed(sd):
	var converted_seed = sd%1000/100.0
	$Cloud.material.set_shader_parameter("seed", converted_seed)
	$Cloud.material.set_shader_parameter("cloud_cover", randf_range(0.35, 0.6))
	$Land.material.set_shader_parameter("seed", converted_seed)

func set_rotates(r):
	$Cloud.material.set_shader_parameter("rotation", r)
	$Land.material.set_shader_parameter("rotation", r)

func update_time(t):
	$Cloud.material.set_shader_parameter("time", t * get_multiplier($Cloud.material) * 0.01)
	$Land.material.set_shader_parameter("time", t * get_multiplier($Land.material) * 0.02)

func set_custom_time(t):
	$Cloud.material.set_shader_parameter("time", t * get_multiplier($Cloud.material) * 0.5)
	$Land.material.set_shader_parameter("time", t * get_multiplier($Land.material))

func set_dither(d):
	$Land.material.set_shader_parameter("should_dither", d)

func get_dither():
	return $Land.material.get_shader_parameter("should_dither")

func get_colors():
	return get_colors_from_shader($Land.material) + get_colors_from_shader($Cloud.material)

func set_colors(colors):
	set_colors_on_shader($Land.material, colors.slice(0, 6))
	set_colors_on_shader($Cloud.material, colors.slice(6, 10))

func randomize_colors():
	var seed_colors = _generate_new_colorscheme(randi()%2+3, randf_range(0.7, 1.0), randf_range(0.45, 0.55))
	var land_colors = []
	var river_colors = []
	var cloud_colors = []
	for i in 4:
		var new_col = seed_colors[0].darkened(i/4.0)
		land_colors.append(Color.from_hsv(new_col.h + (0.2 * (i/4.0)), new_col.s, new_col.v))
	
	for i in 2:
		var new_col = seed_colors[1].darkened(i/2.0)
		river_colors.append(Color.from_hsv(new_col.h + (0.2 * (i/2.0)), new_col.s, new_col.v))
	
	for i in 4:
		var new_col = seed_colors[2].lightened((1.0 - (i/4.0)) * 0.8)
		cloud_colors.append(Color.from_hsv(new_col.h + (0.2 * (i/4.0)), new_col.s, new_col.v))

	set_colors(land_colors + river_colors + cloud_colors)
