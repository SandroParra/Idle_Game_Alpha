extends Resource
class_name DropData

@export var item_scene: PackedScene # La escena física que cae al suelo
@export var drop_chance: float = 0.5
@export var item_data: ItemData # drop name y drop icon movidos a ItemData

@export var item_name: String = "Default Item"

func _ready():
	if item_data:
		apply_item_data()

func apply_item_data():
	if not item_data:
		return
