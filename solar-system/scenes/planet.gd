extends AnimatableBody2D

@export var semi_major_axis: float = 150.0  # Size of the orbit
@export var eccentricity: float = 0.3     # Oval shape (0 = perfect circle, 0.9 = flat oval)
@export var max_trail_length: int = 50 # Controls how long the trail is
@export var orbit_speed: float = 0.5 # 1.0 is default, lower is slower

var angle: float = 0.0
@onready var line_2d: Line2D = $Line2D

func _ready():
	# unpins the line from the planet's movement
	line_2d.top_level = true
	
func _process(delta: float) -> void:
	# 1. Spin the angle over time to make the planet move
	angle += delta * orbit_speed
	
	# 2. Kepler's First Law formula: Calculate distance (r) based on the angle
	# Formula: r = a * (1 - e^2) / (1 + e * cos(angle))
	var e_squared = eccentricity * eccentricity
	var numerator = semi_major_axis * (1.0 - e_squared)
	var denominator = 1.0 + (eccentricity * cos(angle))
	
	var radius = numerator / denominator
	
	# 3. Convert that distance and angle into standard X and Z coordinates
	var x = radius * cos(angle)
	var y = radius * sin(angle)
	
	# 4. Move the planet locally relative to its parent "Orbit" node
	position = Vector2(x, y)
	
	# --- Simple Trail Logic ---
	line_2d.add_point(global_position) # Add current position to the trail
	if line_2d.get_point_count() > max_trail_length:
		line_2d.remove_point(0) # Remove oldest position
