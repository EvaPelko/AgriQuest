extends AnimatableBody2D

@export_category("Orbit Configuration")
@export var semi_major_axis: float = 160.0  # Size of the orbit
@export var eccentricity: float = 0.05     # Oval shape (0 = perfect circle, 0.9 = flat oval)
@export var max_trail_length: int = 200 # Controls how long the trail is
#@export var orbit_speed: float = 20000.0 
#@export var star_gravity_strength: float = 500000.0

@export_category("Astronomical Reference")
# How many kilometers 1 pixel represents in the game universe
@export var pixel_to_km_scale: float = 0.5

@export_category("UI Connections")
@export var speed_label: Label
@export var habitability_label: Label

# --- SELECTION & VISUALS ---
var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

var star_node: SolarStar

var angle: float = 0.0
@onready var line_2d: Line2D = $Line2D

func _ready():
	# unpins the line from the planet's movement
	line_2d.top_level = true
	
	# Start with UI labels and highlight hidden
	set_ui_visible(false)
	
	# wait until the scene tree is 100% finished loading 
	# before running star search
	call_deferred("find_star_and_check")
	
	
func _process(delta: float) -> void:
	if not star_node:
		return
		
	# Fetch the gravity parameter directly from the star
	var star_gravity_strength = star_node.star_gravity_strength
	
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
			#print(str("%.1f" % linear_speed_km))
		else:
			print("Label is missing from the Inspector! Current Speed: ", linear_speed_km)
	
	# POSITIONING & RENDER LOGIC
	# Conversion from polar coordinates (r, θ) to Cartesian coordinates (x, y)
	# Formulas: x = r * cos(θ), y = r * sin(θ)
	var x = radius * cos(angle)
	var y = radius * sin(angle)
	position = Vector2(x, y)
	
	# --- Trail Logic ---
	if position != Vector2.ZERO:
		line_2d.add_point(global_position)
		if line_2d.get_point_count() > max_trail_length:
			line_2d.remove_point(0)
		
	# Mathematically checks if the entire elliptical orbit resides in the Goldilocks zone
func check_orbit_habitability() -> void:
	# Formula for closest point (periapsis)
	var periapsis = semi_major_axis * (1.0 - eccentricity)
	# Formula for furthest point (apoapsis)
	var apoapsis = semi_major_axis * (1.0 + eccentricity)
	
	# Fetch the goldilocks boundaries directly from the star node
	var zone_min = star_node.goldilocks_min_radius
	var zone_max = star_node.goldilocks_max_radius
	
	# Habitability check
	var is_habitable = (periapsis >= zone_min) and (apoapsis <= zone_max)
	
	if habitability_label:
		if is_habitable:
			habitability_label.text = "Orbit Status: HABITABLE"
			habitability_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			habitability_label.text = "Orbit Status: UNINHABITABLE"
			habitability_label.add_theme_color_override("font_color", Color.RED)
			
func find_star_and_check() -> void:
	var found_stars = get_tree().get_nodes_in_group("star")
	
	if found_stars.size() > 0:
		star_node = found_stars[0] as SolarStar
		check_orbit_habitability()
	else:
		push_error("No star found in the 'star' group! Please check your Star node's groups.")

# --- NEW CLICK DETECTION AND TOGGLE SYSTEM ---

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("pressed!")
		get_viewport().set_input_as_handled()
		select_planet()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		deselect_planet()

func select_planet() -> void:
	get_tree().call_group("planets", "deselect_planet")
	set_ui_visible(true)

func deselect_planet() -> void:
	set_ui_visible(false)

# Helper function to clean up UI visibility toggling
func set_ui_visible(visible_state: bool) -> void:
	is_selected = visible_state # This updates the variable and fires queue_redraw()
	if speed_label:
		speed_label.visible = visible_state
	if habitability_label:
		habitability_label.visible = visible_state

# Builtin draw function: Draws a  vector circle when selected
func _draw() -> void:
	if is_selected:
		# Draw a hollow circle around the planet center
		# (Center, Radius: 25px, Start angle, End angle, Points, Color: Cyan, Thickness: 2.0px)
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, Color(0.0, 1.0, 1.0, 0.8), 2.0)
