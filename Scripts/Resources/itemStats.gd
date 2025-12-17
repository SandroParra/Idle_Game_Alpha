class_name ItemData
extends Resource

@export_group("General")
@export var name: String = "Item Name"
@export var rarity: String = "Common" # Common, Uncommon, Rare, Epic

@export_group("Stats")
@export var extra_health: int = 0
@export var extra_damage: int = 0
@export var extra_defense: int = 0
@export var extra_magic_defense: int = 0

@warning_ignore("shadowed_variable")
func generate_item(rarity: String) -> ItemData:
	var item: ItemData = ItemData.new()
	item.rarity = rarity

	# Explicitly type the array as strings
	var possible_stats: Array[String] = ["extra_health", "extra_damage", "extra_defense", "extra_magic_defense"]
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
			"extra_health":
				value = randi_range(10, 50)
			"extra_damage":
				value = randi_range(1, 10)
			"extra_defense":
				value = randi_range(1, 5)
			"extra_magic_defense":
				value = randi_range(1, 5)
			_:
				value = 0
		item.set(stat, value)

	print("Generated item:", item.name, " Rarity:", item.rarity,
		" Stats → Health:", item.extra_health,
		" Damage:", item.extra_damage,
		" Defense:", item.extra_defense,
		" MagicDef:", item.extra_magic_defense)

	return item
