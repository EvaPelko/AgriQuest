extends AnimatableBody2D

@export var semi_major_axis: float = 150.0  # Size of the orbit
@export var eccentricity: float = 0.5     # Oval shape (0 = perfect circle, 0.9 = flat oval)
@export var max_trail_length: int = 50 # Controls how long the trail is
#@export var orbit_speed: float = 20000.0 
@export var star_gravity_strength: float = 500000.0
# How many kilometers 1 pixel represents in the game universe
@export var pixel_to_km_scale: float = 0.5

@export var speed_label: Label

var angle: float = 0.0
@onready var line_2d: Line2D = $Line2D

func _ready():
	# unpins the line from the planet's movement
	line_2d.top_level = true
	
func _process(delta: float) -> void:
	# KEPLER'S FIRST LAW: THE LAW OF ELLIPSES
	# Formula: r = (a * (1 - e^2)) / (1 + e * cos(θ))
	var e_squared = eccentricity * eccentricity
	# p = a * (1 - e^2)  [The semi-latus rectum]
	var numerator = semi_major_axis * (1.0 - e_squared)
	# 1 + e * cos(θ)
	var denominator = 1.0 + (eccentricity * cos(angle))
	# r = p / (1 + e * cos(θ))
	var radius = numerator / denominator
	
	# KEPLER'S THIRD LAW: THE LAW OF HARMONIES
	# Formula: T^2 = (4 * π^2 / μ) * a^3
	var base_orbital_momentum = sqrt(star_gravity_strength * semi_major_axis * (1.0 - e_squared))
	
	# KEPLER'S SECOND LAW: THE LAW OF EQUAL AREAS
	# Formula: dθ/dt = h / r^2
	if radius > 0.0:
		var angular_velocity = base_orbital_momentum / (radius * radius)
		angle += angular_velocity * delta
		
		# --- CALCULATE SPEED FOR DISPLAY ---
		var linear_speed_pixels = base_orbital_momentum / radius
		var linear_speed_km = linear_speed_pixels * pixel_to_km_scale
		
		# Update the label text if it has been assigned
		if speed_label:
			
			# "%.1f" rounds the speed to 1 decimal place
			speed_label.text = "Planet Speed: " + str("%.1f" % linear_speed_km) + " km/s"
			print(str("%.1f" % linear_speed_km))
	
	# POSITIONING & RENDER LOGIC
	# Conversion from polar coordinates (r, θ) to Cartesian coordinates (x, y)
	# Formulas: x = r * cos(θ), y = r * sin(θ)
	var x = radius * cos(angle)
	var y = radius * sin(angle)
	position = Vector2(x, y)
	
	# --- Trail Logic ---
	line_2d.add_point(global_position)
	if line_2d.get_point_count() > max_trail_length:
		line_2d.remove_point(0)
