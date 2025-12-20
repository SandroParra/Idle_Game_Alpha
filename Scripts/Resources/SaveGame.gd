extends Resource
class_name SaveGame

# Variables que queremos guardar en disco
@export var player_name: String = "Hero"
@export var gold: int = 0
@export var current_xp: int = 0

# Inventario Global: Guardaremos los ItemData (Resources) directamente.
# Al ser @export, Godot guardará sus stats únicos (daño, defensa) automáticamente.
@export var global_inventory: Array[ItemData] = []

# Equipamiento por Héroe: Diccionario { "HeroID": { "helmet": ItemData, ... } }
@export var hero_equipment: Dictionary = {
	"BlackDragon": {},
	"MaleViking": {},
	"MaleKnight": {}
}

# Niveles de los héroes (diccionario nombre -> nivel)
@export var hero_levels: Dictionary = {}
