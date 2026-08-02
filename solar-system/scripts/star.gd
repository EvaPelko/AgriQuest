extends AnimatableBody2D

class_name SolarStar # Allows the planet to easily recognize this class

@export var star_gravity_strength: float = 500000.0 # (μ) 
@export var star_luminosity: float = 1.0

# We define 150 pixels as 1 AU relative to the star's frame of reference
var visual_au_pixels: float = 150.0

var goldilocks_min_radius: float = 0.0
var goldilocks_max_radius: float = 0.0

func _ready() -> void:
	# Calculate Goldilocks bounds in pixels once at startup
	var inner_au = sqrt(star_luminosity / 1.1)
	var outer_au = sqrt(star_luminosity / 0.53)
	
	goldilocks_min_radius = inner_au * visual_au_pixels
	goldilocks_max_radius = outer_au * visual_au_pixels
	
	queue_redraw() # Force the star to draw the rings

func _draw() -> void:
	# Draw the visual Goldilocks zone rings around the star
	draw_arc(Vector2.ZERO, goldilocks_min_radius, 0, TAU, 64, Color(0, 1, 0, 0.3), 2.0)
	draw_arc(Vector2.ZERO, goldilocks_max_radius, 0, TAU, 64, Color(0, 1, 0, 0.3), 2.0)
