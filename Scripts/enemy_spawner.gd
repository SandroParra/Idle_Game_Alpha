extends Area2D

var enemyType = preload("res://Scenes/enemies/hyena.tscn")

@export var spawn_interval: float = 2.0
@export var max_enemies: int = 4

var enemies_spawned: int = 0

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_spawn_enemy)

func _on_spawn_enemy():
	if enemies_spawned < max_enemies:
		var enemy = enemyType.instantiate()
		enemy.position = get_random_point_in_rectangle()
		get_parent().add_child(enemy)
		enemies_spawned += 1
		enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed():
	enemies_spawned -= 1

func get_random_point_in_rectangle() -> Vector2:
	var shape = $CollisionShape2D.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		return position + Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
	return position
