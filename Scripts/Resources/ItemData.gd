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

@warning_ignore("shadowed_variable")
func generate_item(rarity: String) -> ItemData:
	var item: ItemData = ItemData.new()
	item.rarity = rarity

	# Explicitly type the array as strings
	var possible_stats: Array[String] = ["health", "attack", "physical_defense", "magical_defense"]
	possible_stats.shuffle()

	var stats_count: int = 1
	match rarity:
		"Common":
			stats_count = 1
		"Uncommon":
			stats_count = 2
		"Rare":
			stats_count = 3
		"Epic":
			stats_count = 4
		_:
			stats_count = 1

	for i in range(stats_count):
		var stat: String = possible_stats[i]
		var value: int = 0
		match stat:
			"health":
				value = randi_range(10, 50)
			"attack":
				value = randi_range(1, 10)
			"defense":
				value = randi_range(1, 5)
			"magic_defense":
				value = randi_range(1, 5)
			_:
				value = 0
		item.set(stat, value)

	print("Generated item:", item.name, " Rarity:", item.rarity,
		" Stats → Health:", item.health,
		" Attack:", item.attack,
		" PhysicalDef:", item.physical_defense,
		" MagicDef:", item.magical_defense
		)

	return item
