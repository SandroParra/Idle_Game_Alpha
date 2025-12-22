class_name EnemyData
extends Resource

@export_group("Visuals")
@export var name: String = "Unit Name"

@export_group("Stats")
@export var health: int = 100
@export var physical_attack: int = 0
@export var magical_attack: int = 0
@export var speed: float = 50.0     # Velocidad en píxeles/segundo
@export var attack_range: float = 50.0
@export var physical_defense: float = 10.0
@export var magical_defense: float = 10.0
@export var crit_chance: float = 5.0
@export var crit_damage: float = 50.0
@export var attack_speed: float = 100.0
@export var xp_gain: int = 0
