extends Resource
class_name FacetData

@export var name: String = "Nombre Faceta"
@export_multiline var description: String = "Descripción..."
@export var icon: Texture2D

# Modificadores (clave-valor)
@export var modifiers: Dictionary = {
	"mod_attack": 0.0,
	"mod_attack_range": 0.0,
	"mod_defense": 0.0,
	"mod_speed": 0.0,
	"mod_attack_speed": 0.0,
	"mod_xp": 0.0,
	"mod_health": 0.0,
	"mod_crit_rate": 0.0,
	"mod_crit_damage": 0.0,
	"mod_regeneration":0.0
	}
