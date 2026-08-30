class_name ClimateGraph
extends Control

var temperature: float = 0.0
var atmosphere: float = 1.0

# Display ranges
var min_temperature: float = -100.0
var max_temperature: float = 100.0

var min_atmosphere: float = 0.0
var max_atmosphere: float = 2.0

var habitable_temp_min: float = -10.0
var habitable_temp_max: float = 30.0

var habitable_atmosphere_min: float = 0.5
var habitable_atmosphere_max: float = 1.5


func set_planet_values(new_temperature: float, new_atmosphere: float) -> void:
	temperature = new_temperature
	atmosphere = new_atmosphere
	queue_redraw()

func set_habitable_temperature_range(
	min_temp: float,
	max_temp: float ) -> void:
	habitable_temp_min = min_temp
	habitable_temp_max = max_temp
	queue_redraw()

func set_habitable_atmosphere_range(
	min_atmosphere: float,
	max_atmosphere: float ) -> void:
	habitable_atmosphere_min = min_atmosphere
	habitable_atmosphere_max = max_atmosphere
	queue_redraw()

func _draw() -> void:
	var center = size / 2.0

	draw_habitable_zone()

	draw_line(
		Vector2(0, center.y),
		Vector2(size.x, center.y),
		Color.WHITE,
		2.0
	)

	draw_line(
		Vector2(center.x, 0),
		Vector2(center.x, size.y),
		Color.WHITE,
		2.0
	)

	draw_planet_marker()
	draw_labels()

func draw_labels() -> void:
	var font = ThemeDB.fallback_font
	var font_size = 14

	# Temperature axis
	draw_string(
		font,
		Vector2(size.x / 2.0 + 10, 20),
		"HOT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE
	)

	draw_string(
		font,
		Vector2(size.x / 2.0 + 10, size.y - 10),
		"COLD",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE
	)

	# Atmosphere axis
	draw_string(
		font,
		Vector2(5, size.y / 2.0 - 10),
		"THIN ATMO",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE
	)

	draw_string(
		font,
		Vector2(size.x / 2.0 + 10, size.y / 2.0 - 10),
		"THICK ATMOSPHERE",
		HORIZONTAL_ALIGNMENT_RIGHT,
		size.x / 2.0 - 15,
		font_size,
		Color.WHITE
	)

func get_planet_position() -> Vector2:
	var x = remap(
		atmosphere,
		min_atmosphere,
		max_atmosphere,
		0.0,
		size.x
	)

	var y = remap(
		temperature,
		min_temperature,
		max_temperature,
		size.y,
		0.0
	)

	return Vector2(x, y)

func draw_habitable_zone() -> void:
	var left = remap(
		habitable_atmosphere_min,
		min_atmosphere,
		max_atmosphere,
		0.0,
		size.x
	)

	var right = remap(
		habitable_atmosphere_max,
		min_atmosphere,
		max_atmosphere,
		0.0,
		size.x
	)

	var top = remap(
		habitable_temp_max,
		min_temperature,
		max_temperature,
		size.y,
		0.0
	)

	var bottom = remap(
		habitable_temp_min,
		min_temperature,
		max_temperature,
		size.y,
		0.0
	)

	var rect = Rect2(
		Vector2(left, top),
		Vector2(
			right - left,
			bottom - top
		)
	)

	draw_rect(
		rect,
		Color(0.2, 0.8, 0.3, 0.5)
	)

func draw_planet_marker() -> void:
	var position = get_planet_position()

	draw_circle(
		position,
		7.0,
		Color.YELLOW
	)
