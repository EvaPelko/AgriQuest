class_name TerraformingData
extends Resource

# --- ROTATIONAL PROPERTIES ---
@export_range(0.0, 90.0, 0.1)
var axial_tilt: float = 23.5

@export_range(1.0, 500.0, 1.0)
var rotation_period_hours: float = 24.0

# --- PLANETARY PROPERTIES ---
@export_range(0.1, 5.0, 0.1)
var mass_earths: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func get_season_severity() -> float:
	return axial_tilt / 90.0
	
func get_season_description() -> String:
	if axial_tilt < 5.0:
		return "Minimal"

	elif axial_tilt < 30.0:
		return "Moderate"

	elif axial_tilt < 55.0:
		return "Strong"

	else:
		return "Extreme"
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
