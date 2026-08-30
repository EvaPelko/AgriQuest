extends AnimatableBody2D

@export_category("Object info")
@export var object_name: String = "Placeholder name"

@export_category("Orbit Configuration")
@export var semi_major_axis: float = 160.0: # Size of the orbit (Controlled by Slider)
	set(value):
		semi_major_axis = max(30.0, value)
		draw_orbit_ring()
		check_orbit_habitability()

@export var eccentricity: float = 0.05: # Oval shape (Controlled by Gizmo) (0 = perfect circle, 0.9 = flat oval)
	set(value):
		eccentricity = clamp(value, 0.0, 0.70)
		draw_orbit_ring()
		check_orbit_habitability()

@export var max_trail_length: int = 200

var current_speed_km: float = 0.0

#@export var rivers: Control

const RIVERS_SCENE = preload("res://pixel_planets/Rivers/Rivers.tscn")
const LAVA_SCENE = preload("res://pixel_planets/LavaWorld/LavaWorld.tscn")
const GAS_GIANT_SCENE = preload("res://pixel_planets/GasPlanetLayers/GasPlanetLayers.tscn")
const DRY_TERRAIN_SCENE = preload("res://pixel_planets/DryTerran/DryTerran.tscn")
const ASTEROID_SCENE = preload("res://pixel_planets/Asteroids/Asteroid.tscn")
const BLACK_HOLE_SCENE = preload("res://pixel_planets/BlackHole/BlackHole.tscn")
const GALAXY_SCENE = preload("res://pixel_planets/Galaxy/Galaxy.tscn")
const ICE_SCENE = preload("res://pixel_planets/IceWorld/IceWorld.tscn")
const NO_ATMOSPHERE_SCENE = preload("res://pixel_planets/NoAtmosphere/NoAtmosphere.tscn")

@onready var planet_visual: Node2D = $PlanetVisual
var active_planet_visual: Node = null

@export_category("Gizmo Setup")
@export var gizmo_handle: OrbitGizmoHandle

# Orbital gravity target
@export var orbit_target: Node2D # If left empty, it defaults to orbiting the Star
@export var default_local_gravity: float = 5000.0 # Fallback gravity used ONLY if the assigned target doesn't specify its own gravity
@export var pixel_to_km_scale: float = 0.5 # How many kilometers 1 pixel represents in the game universe
@export var pixels_per_au: float = 160.0

var is_in_habitable_zone: bool = false # Tracks if the orbit is in the Goldilocks zone

signal planet_selected(planet_ref: Node2D)
signal planet_deselected

@export_category("Terraforming")
@export var terraforming_data = TerraformingData.new()
var is_terraformed: bool = false

# --- VISUAL CONSTANTS ---
const DIM_ALPHA: float = 0.25
const HIGHLIGHT_ALPHA: float = 0.8

var is_selected: bool = false
var star_node: SolarStar
var active_gravity_strength: float = 500000.0
var angle: float = 0.0

@onready var movement_trail: Line2D = $MovementTrail
@onready var orbit_ring: Line2D = $OrbitRing

func _ready() -> void:
	print("Planet visual: ", planet_visual)
	create_planet_visual()
	if movement_trail:
		movement_trail.top_level = true
		movement_trail.z_index = -2
		
	if orbit_ring:
		orbit_ring.top_level = true
		orbit_ring.z_index = -1
		# Start at low transparency by default
		orbit_ring.modulate.a = DIM_ALPHA
	
	# Connect to eccentricity signal instead of resize signal
	if gizmo_handle:
		gizmo_handle.eccentricity_changed.connect(_on_eccentricity_changed_by_gizmo)
	
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

	check_orbit_habitability()
	# Draw the permanent full orbit ring once scene loading completes
	draw_orbit_ring()

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
		current_speed_km = linear_speed_pixels * pixel_to_km_scale
	
	# POSITIONING
	# Conversion from polar coordinates (r, θ) to Cartesian coordinates (x, y)
	# Formulas: x = r * cos(θ), y = r * sin(θ)
	var x = radius * cos(angle)
	var y = radius * sin(angle)
	global_position = orbit_target.global_position + Vector2(x, y)
	
	# MOVEMENT TRAIL LOGIC
	if movement_trail and global_position != Vector2.ZERO:
		movement_trail.add_point(global_position)
		if movement_trail.get_point_count() > max_trail_length:
			movement_trail.remove_point(0)

# --- SELECTION & OPACITY CONTROLS ---

func select_planet() -> void:
	get_tree().call_group("planets", "deselect_planet")
	is_selected = true
	
	# Highlight orbit line smoothly on selection
	if orbit_ring:
		create_tween().tween_property(orbit_ring, "modulate:a", HIGHLIGHT_ALPHA, 0.2)
	
	if gizmo_handle:
		print("Attaching gizmo handle to: ", name)
		gizmo_handle.attach_to_planet(self)
		
	planet_selected.emit(self)
	
	queue_redraw()

func deselect_planet() -> void:
	print("PLANET: deselect_planet() was triggered on ", object_name)
	is_selected = false
	
	# Fade orbit line back down to low transparency
	if orbit_ring:
		create_tween().tween_property(orbit_ring, "modulate:a", DIM_ALPHA, 0.2)
		
	if gizmo_handle:
		gizmo_handle.detach()
		
	planet_deselected.emit()
	
	queue_redraw()

# --- ORBIT RING GEOMETRY ---

func draw_orbit_ring() -> void:
	if not orbit_ring or not orbit_target:
		return
		
	orbit_ring.clear_points()
	
	# Build static 360-degree closed ring path
	var steps = 100
	for i in range(steps + 1):
		var theta = (i / float(steps)) * TAU
		
		var e_squared = eccentricity * eccentricity
		var numerator = semi_major_axis * (1.0 - e_squared)
		var denominator = 1.0 + (eccentricity * cos(theta))
		var r = numerator / denominator
		
		var pt_x = r * cos(theta)
		var pt_y = r * sin(theta)
		
		orbit_ring.add_point(orbit_target.global_position + Vector2(pt_x, pt_y))

# --- COLORS ---

func get_planet_scene() -> PackedScene:
	match terraforming_data.planet_type:
		TerraformingData.PlanetType.RIVERS:
			return RIVERS_SCENE

		TerraformingData.PlanetType.LAVA:
			return LAVA_SCENE

		TerraformingData.PlanetType.GAS_GIANT:
			return GAS_GIANT_SCENE

		TerraformingData.PlanetType.DRY_TERRAIN:
			return DRY_TERRAIN_SCENE

	return RIVERS_SCENE

func create_planet_visual() -> void:
	if not terraforming_data:
		return

	var scene := get_planet_scene()
	active_planet_visual = scene.instantiate()

	planet_visual.add_child(active_planet_visual)
	
	make_materials_unique(active_planet_visual)

	# Make visual sit directly on the orbital body's anchor
	active_planet_visual.scale = Vector2(0.3, 0.3)
	active_planet_visual.position = Vector2(-15, -15)
	
	planet_visual.rotation = deg_to_rad(terraforming_data.axial_tilt)
	
	disable_mouse_on_controls(active_planet_visual)

func disable_mouse_on_controls(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		disable_mouse_on_controls(child)

func make_materials_unique(node: Node) -> void:
	if node is CanvasItem and node.material:
		node.material = node.material.duplicate()

	for child in node.get_children():
		make_materials_unique(child)

func shift_land_color(hue_offset: float) -> void:
	if active_planet_visual and active_planet_visual.has_method("shift_planet_land_hue"):
		active_planet_visual.shift_planet_land_hue(hue_offset)

func shift_rivers_color(hue_offset: float) -> void:
	if active_planet_visual and active_planet_visual.has_method("shift_planet_rivers_hue"):
		active_planet_visual.shift_planet_rivers_hue(hue_offset)

func shift_cloud_color(hue_offset: float) -> void:
	if active_planet_visual and active_planet_visual.has_method("shift_planet_cloud_hue"):
		active_planet_visual.shift_planet_cloud_hue(hue_offset)

func get_current_hue() -> float:
	if active_planet_visual and "current_hue_offset" in active_planet_visual:
		return active_planet_visual.current_hue_offset
	return 0.0

func get_land_hue() -> float:
	if active_planet_visual and active_planet_visual.has_method("get_land_hue"):
		return active_planet_visual.get_land_hue()
	return 0.0

func get_river_hue() -> float:
	if active_planet_visual and active_planet_visual.has_method("get_river_hue"):
		return active_planet_visual.get_river_hue()
	return 0.0

func get_cloud_hue() -> float:
	if active_planet_visual and active_planet_visual.has_method("get_cloud_hue"):
		return active_planet_visual.get_cloud_hue()
	return 0.0
	
# --- TERRAFORMING (axial tilt, rotation) ---
func set_axial_tilt(value: float) -> void:
	if not terraforming_data:
		return

	terraforming_data.axial_tilt = clamp(value, 0.0, 90.0)
	
	planet_visual.rotation = deg_to_rad(terraforming_data.axial_tilt)

func get_axial_tilt() -> float:
	if terraforming_data:
		return terraforming_data.axial_tilt

	return 0.0

func get_temperature() -> float:
	if terraforming_data:
		return terraforming_data.calculate_temperature(get_current_distance_au())

	return 0.0

func get_hottest_temperature() -> float:
	if terraforming_data:
		var periapsis_au = pixels_to_au(get_periapsis())
		var hottest_temp = terraforming_data.calculate_temperature(periapsis_au)
		return hottest_temp

	return 0.0

func get_coldest_temperature() -> float:
	if terraforming_data:
		var apoapsis_au = pixels_to_au(get_apoapsis())
		var coldest_temp = terraforming_data.calculate_temperature(apoapsis_au)
		return coldest_temp

	return 0.0

func get_temperature_difference() -> float:
	if not terraforming_data:
		return 0.0

	var periapsis_au = pixels_to_au(get_periapsis())
	var apoapsis_au = pixels_to_au(get_apoapsis())

	# Closest to star = hottest
	var hottest_temp = terraforming_data.calculate_temperature(periapsis_au)

	# Furthest from star = coldest
	var coldest_temp = terraforming_data.calculate_temperature(apoapsis_au)

	return hottest_temp - coldest_temp
	
func set_rotation_period(value: float) -> void:
	if not terraforming_data:
		return

	terraforming_data.rotation_period_hours = max(1.0, value)

func get_rotation_period() -> float:
	if terraforming_data:
		return terraforming_data.rotation_period_hours

	return 24.0

func set_planet_mass(value: float) -> void:
	if not terraforming_data:
		return

	terraforming_data.mass_earths = max(0.1, value)

func get_planet_mass() -> float:
	if terraforming_data:
		return terraforming_data.mass_earths

	return 1.0

func get_season_description() -> String:
	if terraforming_data:
		return terraforming_data.get_season_description()

	return "Unknown"

# --- GIZMO CALLBACK ---

func _on_eccentricity_changed_by_gizmo(new_e: float) -> void:
	# Ignore resize signals if THIS planet isn't the active selected one
	if not is_selected:
		return
		
	eccentricity = new_e # Setter triggers draw_orbit_ring() & check_orbit_habitability()

# --- HABITABILITY & INPUTS ---

# Mathematically checks if the entire elliptical orbit resides in the Goldilocks zone
func check_orbit_habitability() -> void:
	if star_node:
		# Formula for closest point (periapsis)
		var periapsis = get_periapsis()
		# Formula for furthest point (apoapsis)
		var apoapsis = get_apoapsis()
		
		is_in_habitable_zone = (periapsis >= star_node.goldilocks_min_radius) and (apoapsis <= star_node.goldilocks_max_radius)

func get_periapsis() -> float:
	return semi_major_axis * (1.0 - eccentricity)

func get_apoapsis() -> float:
	return semi_major_axis * (1.0 + eccentricity)
	
func get_current_distance_pixels() -> float:
	var e_squared = eccentricity * eccentricity
	var numerator = semi_major_axis * (1.0 - e_squared)
	var denominator = 1.0 + (eccentricity * cos(angle))

	return numerator / denominator

func pixels_to_au(distance_pixels: float) -> float:
	return distance_pixels / pixels_per_au

func get_current_distance_au() -> float:
	return pixels_to_au(get_current_distance_pixels())

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		select_planet()

func _draw() -> void:
	if is_selected:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, Color(0.0, 1.0, 1.0, 0.8), 2.0)

func mark_terraformed() -> void:
	is_terraformed = true
	
func mark_not_terraformed() -> void:
	is_terraformed = false
