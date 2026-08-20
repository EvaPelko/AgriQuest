#extends "res://scripts/orbital_body.gd"
extends AnimatableBody2D

@export_category("Object info")
@export var object_name: String = "Placeholder name"

@export_category("Orbit Configuration")
@export var semi_major_axis: float = 30
@export var eccentricity: float = 0.05
@export var max_trail_length: int = 200

@export var orbit_target: Node2D # If left empty, it defaults to orbiting the Star
@export var default_local_gravity: float = 5000.0 # Fallback gravity used ONLY if the assigned target doesn't specify its own gravity
@export var pixel_to_km_scale: float = 0.5 # How many kilometers 1 pixel represents in the game universe

# --- VISUAL CONSTANTS ---
const DIM_ALPHA: float = 0.25
const HIGHLIGHT_ALPHA: float = 0.8

var is_selected: bool = false
var star_node: SolarStar
var active_gravity_strength: float = 500000.0
var angle: float = 0.0

#@onready var movement_trail: Line2D = $MovementTrail
#@onready var orbit_ring: Line2D = $OrbitRing

func _ready() -> void:
	#if movement_trail:
		#movement_trail.top_level = true
		#movement_trail.z_index = -2
		
	#if orbit_ring:
		#orbit_ring.top_level = true
		#orbit_ring.z_index = -1
		# Start at low transparency by default
		#orbit_ring.modulate.a = DIM_ALPHA
	
	# Wait until the scene tree is finished loading before setting up targets
	call_deferred("setup_orbit_target")
	
func setup_orbit_target() -> void:
	# 1. If an explicit target was assigned in Inspector (e.g. Moon -> Planet)
	if orbit_target:
		# Try to fetch gravity from the target node or script
		if "star_gravity_strength" in orbit_target:
			active_gravity_strength = orbit_target.star_gravity_strength
		elif "planet_gravity_strength" in orbit_target:
			active_gravity_strength = orbit_target.planet_gravity_strength
		else:
			active_gravity_strength = default_local_gravity
			
		if orbit_target is SolarStar:
			star_node = orbit_target as SolarStar
	# 2. DEFAULT: No target assigned -> Find central Star and fetch ITS gravity
	else:
		var found_stars = get_tree().get_nodes_in_group("star")
		if found_stars.size() > 0:
			star_node = found_stars[0] as SolarStar
			orbit_target = star_node
			# Pull gravity directly from the star node
			if "star_gravity_strength" in star_node:
				active_gravity_strength = star_node.star_gravity_strength
		else:
			push_error("No orbit_target assigned and no Star found in 'star' group!")


func _process(delta: float) -> void:
	if not orbit_target:
		return
		
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
	# Uses the dynamically fetched star or target gravity
	var base_orbital_momentum = sqrt(active_gravity_strength * semi_major_axis * (1.0 - e_squared))
	
	# KEPLER'S SECOND LAW: THE LAW OF EQUAL AREAS
	# Formula: dθ/dt = h / r^2
	if radius > 0.0:
		var angular_velocity = base_orbital_momentum / (radius * radius)
		angle += angular_velocity * delta
		
		# --- CALCULATE SPEED FOR UI ---
		var linear_speed_pixels = base_orbital_momentum / radius
		var linear_speed_km = linear_speed_pixels * pixel_to_km_scale
		#if speed_label:
			#speed_label.text = "Speed: " + str("%.1f" % linear_speed_km) + " km/s"
	
	# POSITIONING
	# Conversion from polar coordinates (r, θ) to Cartesian coordinates (x, y)
	# Formulas: x = r * cos(θ), y = r * sin(θ)
	var x = radius * cos(angle)
	var y = radius * sin(angle)
	global_position = orbit_target.global_position + Vector2(x, y)
	
	
