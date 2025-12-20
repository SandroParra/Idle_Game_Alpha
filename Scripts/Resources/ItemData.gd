extends Resource
class_name ItemData

@export_group("Visuals")
@export var name: String = "Item Name"
@export var icon: Texture2D
@export var rarity: String = "Item Rarity"
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
@export var physical_defense: int = 0
@export var magical_defense: int = 0
@export var defense_mod: float = 0.0
@export var defense_penetration: float = 0.0
@export var health: int = 0
@export var health_mod: float = 0.0
@export var evasion: float = 0.0
@export var block_rate: float = 0.0
#@export var durability: int = 0

func create_instance(rarity_level: String) -> ItemData:
	# 1. Duplicamos ESTE recurso (self). 
	# Esto copia el Icono, Nombre, SlotType y valores base.
	var new_item = self.duplicate()
	
	new_item.rarity = rarity_level
	
	# 2. Modificamos los stats en la COPIA
	var multiplier = 1.0
	match rarity_level:
		"Common": multiplier = 1.0
		"Uncommon": multiplier = 1.2
		"Rare": multiplier = 1.5
		"Epic": multiplier = 2.0
		"Legendary": multiplier = 3.0
	
	# Ejemplo de lógica aleatoria
	if new_item.attack > 0:
		new_item.attack = int(new_item.attack * randf_range(0.9, 1.1) * multiplier) + randi_range(0, 2)
		
	if new_item.health > 0:
		new_item.health = int(new_item.health * randf_range(0.9, 1.1) * multiplier) + randi_range(5, 20)
		
	# Agregar lógica para añadir stats extra que eran 0
	if rarity_level == "Epic" or rarity_level == "Legendary":
		new_item.critical_rate += randf_range(1.0, 5.0)

	return new_item
