extends AnimatableBody2D

@export_category("Object info")
@export var object_name: String = "Placeholder name":
	set(value):
		object_name = value
		# Automatically update the label whenever object_name changes
		if name_label:
			name_label.text = object_name

@export_category("Orbit Configuration")
@export var semi_major_axis: float = 160.0  # Size of the orbit
@export var eccentricity: float = 0.05     # Oval shape (0 = perfect circle, 0.9 = flat oval)
@export var max_trail_length: int = 200 # Controls how long the trail is

# If left empty, it defaults to orbiting the Star
@export var orbit_target: Node2D 

# Fallback gravity used ONLY if the assigned target doesn't specify its own gravity
@export var default_local_gravity: float = 5000.0

@export_category("Astronomical Reference")
# How many kilometers 1 pixel represents in the game universe
@export var pixel_to_km_scale: float = 0.5

@export_category("UI Connections")
@export var name_label: Label
@export var speed_label: Label
@export var habitability_label: Label

signal planet_selected(planet_ref: Node2D)
signal planet_deselected

# --- SELECTION & VISUALS ---
var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

var star_node: SolarStar
var active_gravity_strength: float = 500000.0
var angle: float = 0.0
@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	line_2d.top_level = true
	line_2d.z_index = -1
	line_2d.clear_points()
	
	set_ui_visible(false)
	
	if name_label:
		name_label.text = object_name
		
	# wait until the scene tree is 100% finished loading 
	# before running orbit target search
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

	# 2. DEFAULT: No target assigned -> Find central Star and fetch ITS gravity!
	else:
		var found_stars = get_tree().get_nodes_in_group("star")
		if found_stars.size() > 0:
			star_node = found_stars[0] as SolarStar
			orbit_target = star_node
			
			# Pull gravity directly from the star node
			if "star_gravity_strength" in star_node:
				active_gravity_strength = star_node.star_gravity_strength
			else:
				push_warning("Star node found, but missing 'star_gravity_strength' property.")
		else:
			push_error("No orbit_target assigned and no Star found in 'star' group!")

	check_orbit_habitability()

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
		if speed_label:
			speed_label.text = "Speed: " + str("%.1f" % linear_speed_km) + " km/s"
	
	# POSITIONING
	# Conversion from polar coordinates (r, θ) to Cartesian coordinates (x, y)
	# Formulas: x = r * cos(θ), y = r * sin(θ)
	var x = radius * cos(angle)
	var y = radius * sin(angle)
	global_position = orbit_target.global_position + Vector2(x, y)
	
	# --- Trail Logic ---
	if global_position != Vector2.ZERO:
		line_2d.add_point(global_position)
		if line_2d.get_point_count() > max_trail_length:
			line_2d.remove_point(0)

# Mathematically checks if the entire elliptical orbit resides in the Goldilocks zone
func check_orbit_habitability() -> void:
	if star_node:
		# Formula for closest point (periapsis)
		var periapsis = semi_major_axis * (1.0 - eccentricity)
		# Formula for furthest point (apoapsis)
		var apoapsis = semi_major_axis * (1.0 + eccentricity)
		
		var is_habitable = (periapsis >= star_node.goldilocks_min_radius) and (apoapsis <= star_node.goldilocks_max_radius)
		
		if habitability_label:
			if is_habitable:
				habitability_label.text = "Orbit Status: HABITABLE"
				habitability_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				habitability_label.text = "Orbit Status: UNINHABITABLE"
				habitability_label.add_theme_color_override("font_color", Color.RED)
	else:
		if habitability_label:
			habitability_label.text = "Orbiting Non-Star Target"
			habitability_label.add_theme_color_override("font_color", Color.GRAY)

# --- CLICK & UI LOGIC ---

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		select_planet()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		deselect_planet()

func select_planet() -> void:
	get_tree().call_group("planets", "deselect_planet")
	set_ui_visible(true)
	planet_selected.emit(self)

func deselect_planet() -> void:
	set_ui_visible(false)
	planet_deselected.emit()

func set_ui_visible(visible_state: bool) -> void:
	is_selected = visible_state
	if speed_label:
		speed_label.visible = visible_state
	if habitability_label:
		habitability_label.visible = visible_state
	if name_label:
		name_label.visible = visible_state

func _draw() -> void:
	if is_selected:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, Color(0.0, 1.0, 1.0, 0.8), 2.0)
