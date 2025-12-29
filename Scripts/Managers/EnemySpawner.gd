extends Area2D

signal wave_started(wave: int)
signal wave_completed
signal level_time_finished

@export var wave_sets: Array[WaveSet]
@export var wave_interval: float = 5.0  
@export var spawn_interval: float = 1.0  
@export var require_clear_wave: bool = true
@export var level_time_limit: float = 30.0 # 30 segundos por defecto

@onready var nextWave_Btn = $"../../UI/NextWaveBtn"

var level_timer: Timer
var wave_timer: Timer
var current_wave: int = 0
var wave_budget: int = 0
var enemies_spawned: int = 0
var enemies_to_spawn: Array = []
var enemies_remaining: int = 0

var current_active_set: WaveSet = null

func _ready():
	wave_timer = Timer.new()
	wave_timer.wait_time = wave_interval
	wave_timer.one_shot = true
	add_child(wave_timer)
	wave_timer.timeout.connect(start_next_wave)
	
	# --- CONFIGURAR EL TIMER DE NIVEL ---
	level_timer = Timer.new()
	level_timer.wait_time = level_time_limit
	level_timer.one_shot = true
	add_child(level_timer)
	level_timer.timeout.connect(_on_level_time_reached)
	
	if nextWave_Btn:
			nextWave_Btn.pressed.connect(_on_next_wave_pressed)
			nextWave_Btn.visible = false # Lo ocultamos al inicio

	start_next_wave()

func start_next_wave():
	if nextWave_Btn:	nextWave_Btn.visible = false
		
	current_wave += 1
	emit_signal("wave_started", current_wave)
	
	# 1. BUSCAR EL SET CORRESPONDIENTE A ESTA OLA
	current_active_set = get_set_for_wave(current_wave)
	
	if current_active_set == null:
		print("ERROR CRÍTICO: No hay WaveSet definido para la ola ", current_wave)
		# Intento de fallback
		if not wave_sets.is_empty(): 
			current_active_set = wave_sets.back()
			print("Usando el último set disponible como respaldo.")
		else: 
			print("DETENIDO: El array 'Wave Sets' en el Inspector está VACÍO.")
			return 

	# 2. Calcular presupuesto base * multiplicador del set
	var base_budget = 10 + current_wave * 3
	wave_budget = int(base_budget * current_active_set.budget_multiplier)
	print("Presupuesto calculado: ", wave_budget) # Debug 2
	print("Ola %d iniciada (Set: %d-%d) Presupuesto: %d" % [current_wave, current_active_set.min_wave, current_active_set.max_wave, wave_budget])

	enemies_to_spawn = generate_wave_enemies(wave_budget)
	print("Enemigos generados para spawnear: ", enemies_to_spawn.size()) # Debug 3
	
	if require_clear_wave: 
		level_timer.start(level_time_limit) 

	# Timer para ir soltando los enemigos poco a poco
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_spawn_enemy.bind(timer))
	print("Timer de spawn iniciado") # Debug 4
	
func get_set_for_wave(wave: int) -> WaveSet:
	# Recorremos la lista parametrizable para encontrar el rango
	for set_data in wave_sets:
		if wave >= set_data.min_wave and wave <= set_data.max_wave:
			return set_data
	return null # No se encontró (deberías tener cubiertas todas las olas)

func generate_wave_enemies(budget: int) -> Array:
	var result: Array = []
	var pool = current_active_set.possible_enemies
	
	if pool.is_empty():
		print("Advertencia: El set actual no tiene enemigos asignados.")
		return result

	var safety = 0
	while budget > 0 and safety < 200:
		safety += 1
		
		# Elegir enemigo basado en peso y costo
		var pick = weighted_enemy_pick(budget, pool)
		
		if pick:
			if pick.cost <= budget:
				result.append(pick.scene)
				budget -= pick.cost
			else:
				# Si es muy caro, intentar buscar uno barato en la misma pool
				var cheaper = pool.filter(func(e): return e.cost <= budget)
				if cheaper.is_empty():
					break # Ya no alcanza para nada
				var cheap_pick = cheaper.pick_random()
				result.append(cheap_pick.scene)
				budget -= cheap_pick.cost
		else:
			break
			
	return result

func weighted_enemy_pick(_current_budget: int, pool: Array[SpawnableEnemy]) -> SpawnableEnemy:
	# Filtramos candidatos válidos (que quepan en el presupuesto o casi)
	# Nota: Aquí permitimos elegir incluso si se pasa un poco para luego filtrar en el loop principal,
	# o filtramos estrictamente. Filtremos estrictamente para evitar problemas.
	var candidates = pool
	
	var total_weight = 0.0
	var weights = {}
	
	for enemy in candidates:
		# Peso base * (1 si alcanza, 0.1 si no alcanza pero queremos considerarlo para fallback)
		# Simplificación: Usamos el peso definido en el Recurso
		weights[enemy] = enemy.weight
		total_weight += enemy.weight
		
	var rnd = randf() * total_weight
	var cumulative = 0.0
	
	for enemy in candidates:
		cumulative += weights[enemy]
		if rnd <= cumulative:
			return enemy
			
	return candidates[0]

func _on_spawn_enemy(timer: Timer):
	if enemies_to_spawn.is_empty():
		timer.stop()
		timer.queue_free()
		if not require_clear_wave:
			wave_timer.start()
		return

	var scene = enemies_to_spawn.pop_front()
	var enemy = scene.instantiate()
	enemy.position = get_random_point_in_rectangle()
	get_parent().add_child(enemy)
	enemies_spawned += 1
	enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed():
	enemies_spawned -= 1
	if require_clear_wave:
		if enemies_spawned <= 0 and enemies_to_spawn.is_empty():
			wave_completed.emit()

func _on_next_wave_pressed():
	nextWave_Btn.visible = false
	start_next_wave()

func _on_level_time_reached():
	get_tree().call_group("enemyGroup", "die")
	enemies_to_spawn.clear()
	level_time_finished.emit()

func get_random_point_in_rectangle() -> Vector2:
	var shape = $CollisionShape2D.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		return position + Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
	return position
