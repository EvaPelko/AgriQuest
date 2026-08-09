class_name SystemManager
extends Node2D

@export var camera: Camera2D
@export var terraform_button: Button
@export var orbit_button: Button
@export var gizmo_handle: OrbitGizmoHandle
var can_deselect: bool = true

@export_group("UI Controls")
@export var planet_info_panel: PanelContainer
@export var eccentricity_slider: HSlider
@export var eccentricity_label: Label

var selected_planet: Node2D = null

var is_in_terraforming_mode: bool = false:
	set(value):
		is_in_terraforming_mode = value
		
		# Automatically update UI visibility whenever state changes
		if orbit_button:
			orbit_button.visible = is_in_terraforming_mode
			
		if terraform_button:
			# Hide terraform button when in terraforming mode, 
			# or show it if we are back in system view AND a planet is selected
			terraform_button.visible = (not is_in_terraforming_mode) and (selected_planet != null)
		
		# Hide the right side panel during terraforming mode
		if planet_info_panel:
			planet_info_panel.visible = (not is_in_terraforming_mode) and (selected_planet != null)
			
# Default camera zoom levels
var system_zoom: Vector2 = Vector2(1.0, 1.0)
var terraform_zoom: Vector2 = Vector2(4.0, 4.0)
var default_camera_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	
	if gizmo_handle:
		gizmo_handle.gizmo_interaction_started.connect(_on_gizmo_interaction_started)
		gizmo_handle.gizmo_interaction_ended.connect(_on_gizmo_interaction_ended)
	
	if camera:
		default_camera_position = camera.global_position
		
	if terraform_button:
		terraform_button.visible = false
		terraform_button.pressed.connect(_on_terraform_button_pressed)
	
	if orbit_button:
		orbit_button.visible = false
		orbit_button.pressed.connect(_on_orbit_button_pressed)
	
	if planet_info_panel:
		planet_info_panel.visible = false
		
	if eccentricity_slider:
		eccentricity_slider.value_changed.connect(_on_eccentricity_slider_changed)
		
	# Connect planet signals
	call_deferred("connect_planet_signals")
	
func _on_gizmo_interaction_started() -> void:
	can_deselect = false

func _on_gizmo_interaction_ended() -> void:
	can_deselect = true

func connect_planet_signals() -> void:
	for planet in get_tree().get_nodes_in_group("planets"):
		if planet.has_signal("planet_selected"):
			if not planet.planet_selected.is_connected(on_planet_selected):
				planet.planet_selected.connect(on_planet_selected)
		if planet.has_signal("planet_deselected"):
			if not planet.planet_deselected.is_connected(on_planet_deselected):
				planet.planet_deselected.connect(on_planet_deselected)

func _process(delta: float) -> void:
	if is_in_terraforming_mode and selected_planet and camera:
		camera.global_position = camera.global_position.lerp(selected_planet.global_position, 10.0 * delta)

# --- SELECTION ---

func on_planet_selected(planet: Node2D) -> void:
	selected_planet = planet
	if terraform_button and not is_in_terraforming_mode:
		terraform_button.visible = true
		terraform_button.text = "Terraform " + planet.object_name
	
	if planet_info_panel and not is_in_terraforming_mode:
		planet_info_panel.visible = true
		
	# Populate slider with current planet's eccentricity value
	if eccentricity_slider and "eccentricity" in planet:
		eccentricity_slider.set_value_no_signal(planet.eccentricity)
		_update_eccentricity_label(planet.eccentricity)

func on_planet_deselected() -> void:
	if not is_in_terraforming_mode:
		selected_planet = null
		if terraform_button:
			terraform_button.visible = false
		reset_camera_zoom()
	
	if planet_info_panel:
		planet_info_panel.visible = false
		
# --- BUTTON ACTIONS ---

func _on_eccentricity_slider_changed(value: float) -> void:
	if selected_planet and "eccentricity" in selected_planet:
		selected_planet.eccentricity = value
		_update_eccentricity_label(value)
		
		# Position gizmo handle at the new apoapsis point!
		if gizmo_handle:
			gizmo_handle.update_position()

func _update_eccentricity_label(val: float) -> void:
	if eccentricity_label:
		eccentricity_label.text = "Eccentricity: %.2f" % val
		
func _on_terraform_button_pressed() -> void:
	if not selected_planet:
		return
		
	# Setting this triggers the setter above, hiding terraform_button & showing orbit_button!
	is_in_terraforming_mode = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "zoom", terraform_zoom, 1.0).set_trans(Tween.TRANS_CUBIC)
	print("Entered Terraforming Mode for: ", selected_planet.object_name)

func _on_orbit_button_pressed() -> void:
	# Setting this triggers the setter above, hiding orbit_button & updating terraform_button!
	is_in_terraforming_mode = false
	
	reset_camera_zoom()
	print("Switched to orbit view")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if not can_deselect:
			print("SYSTEM MANAGER: Click ignored! Gizmo is being interacted with.")
			return
			
		print("SYSTEM MANAGER: Deselecting planets because empty space was clicked.")
		get_tree().call_group("planets", "deselect_planet")

func reset_camera_zoom() -> void:
	if not camera:
		return
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "zoom", system_zoom, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_position", default_camera_position, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
