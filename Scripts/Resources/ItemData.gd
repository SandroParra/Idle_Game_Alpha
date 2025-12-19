extends Resource
class_name ItemData

@export_group("Visuals")
@export var name: String = "Item Name"
@export var icon: Texture2D
@export var type: String = "Item Rarity"
#@export var price: int = 0

@export_group("System")
# IMPORTANTE: Este texto debe coincidir con PlayerData.SLOTS (ej: "helmet", "chest", "right_weapon")
@export var slot_type: String = "helmet" 

@export_group("Stats")
# Aquí puedes agregar los stats que da el item
@export var range_mod: float = 0.0
@export var attack_mod: float = 0.0
@export var attack: int = 0
@export var accuracy: int = 0
@export var critical_rate: float = 0.0
@export var critical_damage: int = 0
@export var defense: int = 0
@export var defense_mod: float = 0.0
@export var defense_penetration: float = 0.0
@export var health: int = 0
@export var health_mod: float = 0.0
@export var evasion: float = 0.0
@export var block_rate: float = 0.0
#@export var durability: int = 0
