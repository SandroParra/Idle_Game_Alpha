extends Node2D

@export var enemy_type_a : PackedScene
@export var enemy_type_b : PackedScene
@onready var spawn_area = $spawnArea
var spawn_a := true
var enemies_spawned := 0
const max_enemies := 4

func _on_timer_timeout() -> void:												
	#spawn an enemy
	if enemies_spawned >= max_enemies:
		$Timer.stop()
		return
		
	var enemy = enemy_type_a.instantiate() if spawn_a else enemy_type_b.instantiate()
	enemy.global_position = get_random_position()
	add_child(enemy)
	enemies_spawned += 1
	spawn_a = !spawn_a 
		

func get_random_position() -> Vector2:
	var shape = spawn_area.get_node("CollisionShape2D").shape
	if(shape is RectangleShape2D):
		var extents = shape.extents
		var random_x = randf_range(-extents.x, extents.x)
		var random_y = randf_range(-extents.y, extents.y)
		return spawn_area.global_position + Vector2(random_x, random_y)
	return spawn_area.global_position
		
