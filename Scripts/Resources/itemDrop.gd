class_name ItemPickup
extends Node2D

@export var data: ItemData
@export var item_name: String = "Default Item"

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	if data:
		apply_item_data()

func apply_item_data():
	if not data:
		return

	data.name = item_name
	if sprite:
		match data.rarity:
			"Common":   sprite.modulate = Color(1, 1, 1, 1)
			"Uncommon": sprite.modulate = Color(0, 1, 0, 1)
			"Rare":     sprite.modulate = Color(0, 0, 1, 1)
			"Epic":     sprite.modulate = Color(0.6, 0, 0.6, 1)

	print("Dropped:", data.name, " Rarity:", data.rarity,
		" Stats → Health:", data.extra_health,
		" Damage:", data.extra_damage,
		" Defense:", data.extra_defense,
		" MagicDef:", data.extra_magic_defense)
