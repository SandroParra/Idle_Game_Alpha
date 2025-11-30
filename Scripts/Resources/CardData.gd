class_name CardData extends Resource

@export_group("Visuals")
@export var name: String = "Unit Name"
@export var icon: Texture2D          # Para la UI
@export var unit_scene: PackedScene  # La escena del personaje (Unit.tscn)

@export_group("Stats")
@export var cost: int = 3
@export var health: int = 100
@export var damage: int = 15
@export var speed: float = 100.0     # Velocidad en píxeles/segundo
@export var attack_range: float = 50.0
