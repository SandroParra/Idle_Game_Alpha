extends Resource
class_name DropData

@export var item_scene: PackedScene
@export_range(0, 1) var drop_chance: float = 0.5 
@export var item_data: ItemData 

@export_group("Rarity Probability")
# Por defecto ponemos valores bajos para los altos
@export_range(0, 1) var chance_legendary: float = 0.01 # 1%
@export_range(0, 1) var chance_epic: float = 0.05      # 5%
@export_range(0, 1) var chance_rare: float = 0.15      # 15%
@export_range(0, 1) var chance_uncommon: float = 0.40  # 40%
# Si falla todo lo anterior, será Common automáticamente.

# Función para determinar la rareza basada en las probabilidades de ESTE drop específico
func resolve_rarity() -> String:
	var roll = randf()
	
	# Chequeo en cascada (de más difícil a más fácil)
	if roll < chance_legendary: return "Legendary"
	if roll < chance_epic: return "Epic"
	if roll < chance_rare: return "Rare"
	if roll < chance_uncommon: return "Uncommon"
	
	return "Common"
