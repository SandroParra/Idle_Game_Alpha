extends Resource
class_name dropData

@export var item_scene: PackedScene
@export var drop_chance: float = 0.1
@export var icon: Texture2D  # Para mostrar en la UI
@export var item_name: String = "Item"
@export var min_rarity: String = "Common" # optional: control rarity floor
