extends Area2D

var enemy_list = {
	"Ogre": {
		"scene": preload("res://Scenes/Units/enemies/Ogre.tscn"),
		"cost": 3
	},
	"BigTick": {
		"scene": preload("res://Scenes/Units/enemies/BigTick.tscn"),
		"cost": 1
	}
}

signal wave_started(wave: int)
signal wave_completed
@export var wave_interval: float = 5.0  
@export var spawn_interval: float = 1.0  
@export var require_clear_wave: bool = true

@onready var nextWave_Btn = $"../../UI/NextWaveBtn"

var wave_timer: Timer
var current_wave: int = 0
var wave_budget: int = 0
var enemies_spawned: int = 0
var enemies_to_spawn: Array = []
var enemies_remaining: int = 0

func _ready():
	wave_timer = Timer.new()
	wave_timer.wait_time = wave_interval
	wave_timer.one_shot = true
	add_child(wave_timer)
	wave_timer.timeout.connect(start_next_wave)
	
	if nextWave_Btn:
			nextWave_Btn.pressed.connect(_on_next_wave_pressed)
			nextWave_Btn.visible = false # Lo ocultamos al inicio

	start_next_wave()

func start_next_wave():
	if nextWave_Btn:
		nextWave_Btn.visible = false
		
	emit_signal("wave_started", current_wave + 1)
	current_wave += 1
	wave_budget = 5 + current_wave * 2
	print("Wave %d starting with %d credits" % [current_wave, wave_budget])

	enemies_to_spawn = generate_wave_enemies(wave_budget)

	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_spawn_enemy.bind(timer))
	
func _on_next_wave_pressed():
	nextWave_Btn.visible = false
	start_next_wave()

func generate_wave_enemies(budget: int) -> Array:
	var result: Array = []
	var keys = enemy_list.keys()

	while budget > 0:
		var choice = weighted_enemy_pick(budget)
		var cost = enemy_list[choice]["cost"]

		if cost <= budget:
			result.append(enemy_list[choice]["scene"])
			budget -= cost
		else:
			# If too expensive, fallback to cheaper options
			var cheaper = keys.filter(func(k): return enemy_list[k]["cost"] <= budget)
			if cheaper.is_empty():
				break
			choice = cheaper[randi() % cheaper.size()]
			result.append(enemy_list[choice]["scene"])
			budget -= enemy_list[choice]["cost"]

	return result

func _on_spawn_enemy(timer: Timer):
	if enemies_to_spawn.is_empty():
		timer.stop()
		timer.queue_free()
		
		if not require_clear_wave:
			# Timed mode: wait before next wave
			wave_timer.start()
		# In clear-wave mode, do nothing here — wait until all enemies are gone
		return

	var enemyPicked = enemies_to_spawn.pop_front()
	var enemy = enemyPicked.instantiate()
	enemy.position = get_random_point_in_rectangle()
	get_parent().add_child(enemy)
	enemies_spawned += 1
	enemy.tree_exited.connect(_on_enemy_removed)
	
func weighted_enemy_pick(budget: int) -> String:
	var weights: Dictionary = {}
	var total_weight: float = 0.0

	for key in enemy_list.keys():
		var cost = enemy_list[key]["cost"]
		
		var weight = max(1.0, float(budget) / float(cost))
		weights[key] = weight
		total_weight += weight

	# Pick based on weights
	var rnd = randf() * total_weight
	var cumulative = 0.0
	for key in weights.keys():
		cumulative += weights[key]
		if rnd <= cumulative:
			return key

	return enemy_list.keys()[0]  # fallback

func _on_enemy_removed():
	enemies_spawned -= 1
	
	if require_clear_wave:
			# Si ya no quedan enemigos vivos Y ya no hay enemigos en cola para salir
			if enemies_spawned <= 0 and enemies_to_spawn.is_empty():
				print("Ola completada. Emitiendo señal...")
				wave_completed.emit()

func get_random_point_in_rectangle() -> Vector2:
	var shape = $CollisionShape2D.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		return position + Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
	return position
