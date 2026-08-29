class_name SystemManager
extends Node2D

@export var camera: Camera2D
@export var terraform_button: Button
@export var orbit_button: Button
@export var gizmo_handle: OrbitGizmoHandle
var can_deselect: bool = true

var terraforming_energy: int = 10
@export var terraforming_energy_label: Label

@export_category("Planet info")
@export var name_label: Label
@export var speed_label: Label
@export var habitability_zone_label: Label
@export var season_label: Label
@export var temperature_label: Label
@export var temperature_range_label: Label

@export_group("UI Controls")
@export var terraforming_hud_canvas: CanvasLayer
@export var planet_info_canvas: CanvasLayer
@export var planet_info_panel: PanelContainer
@export var orbit_size_slider: HSlider   # Formerly eccentricity_slider
@export var orbit_size_label: Label     # Displays current orbit radius/a
@export var terraforming_panel: PanelContainer
@export var land_color_slider: HSlider
@export var land_color_label: Label
@export var rivers_color_slider: HSlider
@export var rivers_color_label: Label
@export var cloud_color_slider: HSlider
@export var cloud_color_label: Label
@export var axial_tilt_panel: PanelContainer
@export var axial_tilt_slider: HSlider
@export var axial_tilt_label: Label
@export var add_greenhouse_gasses_button: Button
@export var remove_greenhouse_gasses_button: Button
@export var add_geothermal_heat_button: Button
@export var remove_geothermal_heat_button: Button
@export var add_nitrogen_button: Button

@export var climate_graph: Control

@export var end_screen_canvas: CanvasLayer
@export var restart_button: Button

var selected_planet: Node2D = null

var is_in_terraforming_mode: bool = false:
	set(value):
		is_in_terraforming_mode = value
		
		if terraforming_hud_canvas:
			if is_in_terraforming_mode:
				terraforming_hud_canvas.show()
			else:
				terraforming_hud_canvas.hide()
				
		# Automatically update UI visibility whenever state changes
		if orbit_button:
			orbit_button.visible = is_in_terraforming_mode
			
		if terraform_button:
			# Hide terraform button when in terraforming mode, 
			# or show it if we are back in system view AND a planet is selected
			terraform_button.visible = (not is_in_terraforming_mode) and (selected_planet != null)
		
		# Hide the  orbit panel during terraforming mode
		if planet_info_panel:
			planet_info_panel.visible = (not is_in_terraforming_mode) and (selected_planet != null)
			
			
# Default camera zoom levels
var system_zoom: Vector2 = Vector2(1.0, 1.0)
var terraform_zoom: Vector2 = Vector2(4.0, 4.0)
var default_camera_position: Vector2 = Vector2.ZERO

func _ready() -> void:
				
	if planet_info_canvas:
			if selected_planet:
				planet_info_canvas.show()
			else:
				planet_info_canvas.hide()
	
	if terraforming_hud_canvas:
			if is_in_terraforming_mode:
				terraforming_hud_canvas.show()
			else:
				terraforming_hud_canvas.hide()
	
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
		
	if orbit_size_slider:
		# Set slider bounds for semi-major axis (e.g. 100 to 2000 pixels)
		orbit_size_slider.min_value = 100.0
		orbit_size_slider.max_value = 300.0
		orbit_size_slider.step = 5.0
		orbit_size_slider.value_changed.connect(_on_orbit_size_slider_changed)
		
	if gizmo_handle:
		gizmo_handle.eccentricity_changed.connect(_on_gizmo_eccentricity_changed)
		
	# Connect planet signals
	call_deferred("connect_planet_signals")
	
	# Setup and connect color slider
	if land_color_slider:
		land_color_slider.min_value = 0.0
		land_color_slider.max_value = 1.0
		land_color_slider.step = 0.01
		land_color_slider.value_changed.connect(_on_land_color_slider_value_changed)
	
	if rivers_color_slider:
		rivers_color_slider.value_changed.connect(_on_rivers_color_slider_value_changed)
	
	if cloud_color_slider:
		cloud_color_slider.value_changed.connect(_on_cloud_color_slider_value_changed)
	
	if axial_tilt_slider:
		axial_tilt_slider.value_changed.connect(_on_axial_tilt_slider_value_changed)
	
	if add_greenhouse_gasses_button:
		add_greenhouse_gasses_button.pressed.connect(_on_add_greenhouse_button_pressed)
	
	if remove_greenhouse_gasses_button:
		remove_greenhouse_gasses_button.pressed.connect(_on_remove_greenhouse_button_pressed)
	
	if add_geothermal_heat_button:
		add_geothermal_heat_button.pressed.connect(_on_add_heat_button_pressed)
	
	if remove_geothermal_heat_button:
		remove_geothermal_heat_button.pressed.connect(_on_remove_heat_button_pressed)
	
	if add_nitrogen_button:
		add_nitrogen_button.pressed.connect(_on_add_nitrogen_button_pressed)
	
	if terraforming_energy_label:
		_update_terraforming_energy_label()
	
	if end_screen_canvas:
		end_screen_canvas.visible = false
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	
func _on_land_color_slider_value_changed(value: float) -> void:
	if selected_planet and selected_planet.has_method("shift_land_color"):
		selected_planet.shift_land_color(value)

func _on_rivers_color_slider_value_changed(value: float) -> void:
	if selected_planet and selected_planet.has_method("shift_rivers_color"):
		selected_planet.shift_rivers_color(value)

func _on_cloud_color_slider_value_changed(value: float) -> void:
	if selected_planet and selected_planet.has_method("shift_cloud_color"):
		selected_planet.shift_cloud_color(value)

func _on_axial_tilt_slider_value_changed(value: float) -> void:
	if not selected_planet:
		return

	if selected_planet.has_method("set_axial_tilt"):
		selected_planet.set_axial_tilt(value)
	
	if season_label:
		var season = selected_planet.get_season_description()
		season_label.text = "Season variability: " + season

	_update_axial_tilt_label(value)
	
func _update_axial_tilt_label(value: float) -> void:
	if axial_tilt_label:
		axial_tilt_label.text = "Axial tilt: " + "%.1f°" % value

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
	if selected_planet and speed_label:
		speed_label.text = "Speed: " + str("%.1f" % selected_planet.current_speed_km) + " km/s"
	
	if selected_planet and temperature_label:
		temperature_label.text = "Temperature: " + str("%.1f" % selected_planet.get_temperature()) + " °C"
	
	if selected_planet and temperature_range_label:
		temperature_range_label.text = "Temperature range: " + str("%.1f" % selected_planet.get_coldest_temperature()) + " °C  -  " + str("%.1f" % selected_planet.get_hottest_temperature()) + " °C"
	
	if is_in_terraforming_mode and selected_planet and camera:
		camera.global_position = camera.global_position.lerp(selected_planet.global_position, 10.0 * delta)

# --- SELECTION ---

func on_planet_selected(planet: Node2D) -> void:
	selected_planet = planet
	
	if name_label and "object_name" in planet:
		name_label.text = planet.object_name
	
	if planet_info_canvas:
			if selected_planet:
				planet_info_canvas.show()
			else:
				planet_info_canvas.hide()
	
	if habitability_zone_label:
			if planet.is_in_habitable_zone:
				habitability_zone_label.text = "Orbit Status: IN HABITABLE ZONE"
				habitability_zone_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				habitability_zone_label.text = "Orbit Status: UNINHABITABLE"
				habitability_zone_label.add_theme_color_override("font_color", Color.RED)
	
	if season_label:
		var season = planet.get_season_description()
		season_label.text = "Season variability: " + season
	
	if terraform_button and not is_in_terraforming_mode:
		terraform_button.visible = true
		terraform_button.text = "Terraform " + planet.object_name
		_update_terraform_button_state()
	
	if planet_info_panel and not is_in_terraforming_mode:
		planet_info_panel.visible = true
		
	# Populate slider with planet's semi_major_axis
	if orbit_size_slider and "semi_major_axis" in planet:
		orbit_size_slider.set_value_no_signal(planet.semi_major_axis)
		_update_size_label(planet.semi_major_axis)
	
	if land_color_slider and planet.has_method("get_land_hue"):
		land_color_slider.set_value_no_signal(planet.get_land_hue())
	
	if rivers_color_slider and planet.has_method("get_river_hue"):
		rivers_color_slider.set_value_no_signal(planet.get_river_hue())
	
	if cloud_color_slider and planet.has_method("get_cloud_hue"):
		cloud_color_slider.set_value_no_signal(planet.get_cloud_hue())
	
	if axial_tilt_slider and planet.has_method("get_axial_tilt"):
		axial_tilt_slider.set_value_no_signal(planet.get_axial_tilt())
		_update_axial_tilt_label(planet.get_axial_tilt())
	
	_update_climate_graph()

# Helper function to grey out / enable the terraform button dynamically
func _update_terraform_button_state() -> void:
	if terraform_button and selected_planet:
		if "is_in_habitable_zone" in selected_planet:
			# Button is disabled (greyed out) if NOT habitable
			terraform_button.disabled = not selected_planet.is_in_habitable_zone
		else:
			terraform_button.disabled = false

func _update_habitability_label_state() -> void:
	if habitability_zone_label:
			if selected_planet.is_in_habitable_zone:
				habitability_zone_label.text = "Orbit Status: IN HABITABLE ZONE"
				habitability_zone_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				habitability_zone_label.text = "Orbit Status: UNINHABITABLE"
				habitability_zone_label.add_theme_color_override("font_color", Color.RED)

func on_planet_deselected() -> void:
	if not is_in_terraforming_mode:
		if planet_info_panel:
			planet_info_panel.visible = false
	
		if planet_info_canvas:
			if selected_planet:
				planet_info_canvas.show()
			else:
				planet_info_canvas.hide()
				
		selected_planet = null
		if terraform_button:
			terraform_button.visible = false
		reset_camera_zoom()
		
#--- SLIDER CALLBACK (Changes Orbit Size) ---

func _on_orbit_size_slider_changed(value: float) -> void:
	if selected_planet and "semi_major_axis" in selected_planet:
		selected_planet.semi_major_axis = value
		_update_size_label(value)
		_update_terraform_button_state()
		_update_habitability_label_state()
		
		# Reposition gizmo handle to match new orbit scale
		if gizmo_handle:
			gizmo_handle.update_position()

# --- GIZMO CALLBACK (Changes Eccentricity) ---

func _on_gizmo_eccentricity_changed(new_e: float) -> void:
	if selected_planet and "eccentricity" in selected_planet:
		selected_planet.eccentricity = new_e
		_update_terraform_button_state()
		_update_habitability_label_state()

func _update_size_label(val: float) -> void:
	if orbit_size_label:
		orbit_size_label.text = "Orbit Size: %d " % int(val)
		
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
	
	if planet_info_panel:
		planet_info_panel.visible = false

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
	
# TERRAFORMING
func _update_terraforming_energy_label() -> void:
	if terraforming_energy_label:
		terraforming_energy_label.text = "Terraforming energy: " + str(terraforming_energy)
		
func _on_add_greenhouse_button_pressed() -> void:
	if not selected_planet:
		return

	selected_planet.terraforming_data.add_greenhouse_gases(0.1)
	terraforming_energy -= 1
	
	_update_terraforming_energy_label()
	_update_climate_graph()

	#_update_temperature_ui()
	_check_terraforming_goal()

func _on_remove_greenhouse_button_pressed() -> void:
	if not selected_planet:
		return

	selected_planet.terraforming_data.remove_greenhouse_gases(0.1)
	terraforming_energy -= 1
	
	_update_terraforming_energy_label()
	_update_climate_graph()

	#_update_temperature_ui()
	_check_terraforming_goal()

func _on_add_heat_button_pressed() -> void:
	if not selected_planet:
		return

	selected_planet.terraforming_data.add_geothermal_heat(5)
	terraforming_energy -= 1
	
	_update_terraforming_energy_label()
	_update_climate_graph()

	#_update_temperature_ui()
	_check_terraforming_goal()

func _on_remove_heat_button_pressed() -> void:
	if not selected_planet:
		return

	selected_planet.terraforming_data.remove_geothermal_heat(5)
	terraforming_energy -= 1
	
	_update_terraforming_energy_label()
	_update_climate_graph()

	#_update_temperature_ui()
	_check_terraforming_goal()

func _on_add_nitrogen_button_pressed() -> void:
	if not selected_planet:
		return

	selected_planet.terraforming_data.add_nitrogen(0.1)
	terraforming_energy -= 1
	
	_update_terraforming_energy_label()
	_update_climate_graph()

	#_update_temperature_ui()
	_check_terraforming_goal()

func _update_climate_graph() -> void:
	if not selected_planet or not climate_graph:
		return

	climate_graph.set_planet_values(
		selected_planet.get_temperature(),
		selected_planet.terraforming_data.atmosphere_density
	)

func _check_terraforming_goal() -> void:
	
	var temp = selected_planet.get_temperature()
	
	var temp_ok = temp >= 0.0 and temp <= 30.0
	var temp_variation_ok = selected_planet.get_temperature_difference() <= 20.0
	var season = selected_planet.get_season_description()

	var seasons_ok = (
		season == "Minimal"
		or season == "Moderate")
	
	if temp_ok and temp_variation_ok and seasons_ok:
		print("PLANET HABITABLE!")
		selected_planet.mark_terraformed()
		_check_all_planets_finished()

func _check_all_planets_finished() -> void:
	var planets = get_tree().get_nodes_in_group("planets")

	for planet in planets:
		if not planet.is_terraformed:
			return

	_show_end_screen()

func _show_end_screen() -> void:
	end_screen_canvas.visible = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
