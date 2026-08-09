class_name OrbitGizmoHandle
extends Area2D

# Emitted when dragging to inform the target planet of its new semi-major axis
signal orbit_resized(new_semi_major_axis: float)

signal gizmo_interaction_started
signal gizmo_interaction_ended   

var target_planet: Node2D = null
var is_dragging: bool = false
var is_hovered: bool = false # Tracks if mouse is over the handle shape

func _ready() -> void:
	input_pickable = true
	visible = false
	z_index = 10 # Force rendering on top of planets and orbit lines

	# Connect collision hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	is_hovered = true
	gizmo_interaction_started.emit()
	print("gizmo interacting")

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_dragging:
		gizmo_interaction_ended.emit()
		print("gizmo not interacting")

# Attach handle to a newly selected planet
func attach_to_planet(planet: Node2D) -> void:
	target_planet = planet
	visible = true
	print("gizmo handle is visible")
	update_position()

# Hide and release reference when planet is deselected
func detach() -> void:
	target_planet = null
	is_dragging = false
	visible = false

# Reposition handle at the Apoapsis (furthest distance) on the orbit path
func update_position() -> void:
	if not target_planet or is_dragging:
		return
		
	var a = target_planet.semi_major_axis
	var e = target_planet.eccentricity
	var apoapsis_dist = a * (1.0 + e)
	
	# Determine reference star position
	var star_center = target_planet.global_position
	if target_planet.orbit_target:
		star_center = target_planet.orbit_target.global_position
	
	# Place handle on apoapsis point
	global_position = star_center + Vector2(-apoapsis_dist, 0)

# Input handling for dragging
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			# Emit IMMEDIATELY on mouse click before input propagates
			gizmo_interaction_started.emit()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			get_viewport().set_input_as_handled()
			if not is_hovered:
				gizmo_interaction_ended.emit()

func is_active_and_dragging() -> bool:
	return visible and is_dragging

func _process(_delta: float) -> void:
	if not target_planet or not target_planet.orbit_target:
		return
		
	if is_dragging:
		# Drag handle to global mouse coordinates
		var mouse_pos = get_global_mouse_position()
		global_position = mouse_pos
		
		# Distance between mouse cursor and central target star/planet
		var star_pos = target_planet.orbit_target.global_position
		var mouse_dist = star_pos.distance_to(mouse_pos)
		
		# Reverse Kepler formula: a = r_apoapsis / (1 + e)
		var new_a = mouse_dist / (1.0 + target_planet.eccentricity)
		
		# Emit signal to inform planet script to update live
		orbit_resized.emit(new_a)
	else:
		# Lock gizmo to Apoapsis point continuously
		update_position()
