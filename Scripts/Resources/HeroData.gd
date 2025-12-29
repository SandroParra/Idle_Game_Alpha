class_name HeroData
extends Resource

@export_group("Visuals")
@export var name: String = "Unit Name"
@export var icon: Texture2D          # Para la UI
@export var unit_scene: PackedScene  # La escena del personaje (Unit.tscn)

@export_group("Stats")
@export var cost: int = 1
@export var health: int = 100
@export var physical_attack: int = 15
@export var magical_attack: int = 15
#@export var accuracy: int = 0
@export var speed: float = 50.0     # Velocidad en píxeles/segundo
@export var attack_range: float = 50.0
@export var physical_defense: float = 10.0
@export var magical_defense: float = 10.0
#@export var evasion: float = 0.0
#@export var block_rate: float = 0.0
@export var defense_penetration: float = 0.0
@export var critical_rate: float = 5.0
@export var critical_damage: float = 50.0
@export var attack_speed: float = 100.0
@export var xp: float = 10.0


@export_group("Skills")
@export var skill_1: String = "Skill 1"
@export var skill_2: String = "Skill 2"
@export var skill_3: String = "Skill 3"

@export_group("Facets")
# Esta es la lista que el HeroManager está buscando y no encontraba
@export var available_facets: Array[FacetData] = []
