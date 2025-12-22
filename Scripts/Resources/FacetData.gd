extends Resource
class_name FacetData

@export var name: String = "Nombre Faceta"
@export_multiline var description: String = "Descripción..."
@export var icon: Texture2D

# Modificadores (clave-valor)
@export var modifiers: Dictionary = {
	"attack_mod": 0.0,
	"physical_attack": 0.0,
	"magical_attack": 0.0,
	"physical_defense": 0.0,
	"magical_defense": 0.0,
	"defense_mod": 0.0,
	"defense_penetration": 0.0,
	"speed": 0.0,
	"attack_speed": 0.0,
	"xp": 0.0,
	"health": 0.0,
	"crit_rate": 0.0,
	"crit_damage": 0.0
	}
