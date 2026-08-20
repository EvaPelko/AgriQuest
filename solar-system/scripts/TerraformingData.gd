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
@export var atmosphere_density: float = 1.0
@export var greenhouse_strength: float = 0.3
@export var albedo: float = 0.3
@export var geothermal_heat: float = 0.0
@export var water_amount: float = 0.5

var temperature: float = 0.0

enum PlanetType {
	RIVERS,
	LAVA,
	GAS_GIANT,
	DRY_TERRAIN,
	ICE,
	ASTEROID,
	BLACK_HOLE,
	GALAXY,
	NO_ATMOSPHERE
}

@export var planet_type: PlanetType = PlanetType.RIVERS

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
		
func generate_planet_type(distance_from_star: float) -> String:
	if distance_from_star < 80.0:
		return "lava"
	elif distance_from_star < 180.0:
		return "rocky"
	elif distance_from_star < 300.0:
		return "ice"
	else:
		return "gas_giant"		

func determine_planet_type() -> PlanetType:
	if temperature > 80.0 and water_amount < 0.2:
		return PlanetType.LAVA

	if temperature < -20.0:
		return PlanetType.ICE

	if water_amount > 0.7:
		return PlanetType.RIVERS

	return PlanetType.DRY_TERRAIN

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
