extends Resource
class_name WaveSet

@export_group("Rango de Activación")
@export var min_wave: int = 1
@export var max_wave: int = 1

@export_group("Pool de Enemigos")
# Aquí arrastrarás los recursos SpawnableEnemy que creaste en el paso 1
@export var possible_enemies: Array[SpawnableEnemy]

@export_group("Ajustes de Ola")
@export var budget_multiplier: float = 1.0 # Útil para Bosses (puedes dar mucho o poco presupuesto)
