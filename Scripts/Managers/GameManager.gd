extends Node2D

@export var valid_spawn_area: Rect2 
@export var card_ui_scene: PackedScene
@export var reward_ui_scene: PackedScene
@export var warning_time_threshold: float = 10.0 

@export_group("Energy System")
@export var max_energy: int = 30
@export var energy_regen_rate: float = 2.0 
@export var starting_energy: int = 5 

signal xp_updated(new_amount: int)
signal hero_level_changed(hero_name: String, new_level: int)
signal energy_updated(current: int, max_amount: int)

var current_xp: int = 0
var current_card: HeroData = null
var current_energy: int = 0
var energy_timer: float = 0.0
var ghost_sprite: Sprite2D 
var is_dragging: bool = false
var current_wave_loot: Array[ItemData] = []
var is_normal_mode: bool = true 
var is_game_over_processing: bool = false

@export_group("UI References")
@export var xp_ui_icon: TextureRect # O Sprite2D, según lo que sea
@export var xp_label: Label
@export var endless_btn: BaseButton
@export var normal_btn: BaseButton
@export var hud_timer_panel: Control
@export var wave_label: Label
@export var wave_time: Label
@export var energy_ui: Control # O EnergyBar si tienes class_name
@export var selector: Control

@export_group("Game References")
@export var spawner: Node2D # O tu clase EnemySpawner

var hero_levels: Dictionary = {}

func get_closest_enemy(reference_position: Vector2)->CharacterBody2D:
	var closest_enemy = null
	var shortest_distance = INF
	var enemies = get_tree().get_nodes_in_group("enemyGroup")

	if enemies.is_empty():
		return null
		
	for enemy in enemies:
		if enemy == null: continue
			
		var distance = reference_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy
	return closest_enemy
	
func _ready():
	# IMPORTANTE: No necesitas add_to_group("gamemanager") si usas AutoLoad, 
	# pero no hace daño dejarlo.
	add_to_group("gamemanager")
	current_energy = starting_energy
	
	if energy_ui and energy_ui.has_method("update_bar"):
		energy_updated.connect(energy_ui.update_bar)
	else:
		print("ERROR: No se encontró EnergyBar o le falta el script")
		
	energy_updated.emit(current_energy, max_energy)
	
	if endless_btn: endless_btn.pressed.connect(_on_endless_pressed)
	if normal_btn: normal_btn.pressed.connect(_on_normal_pressed)
	
	ghost_sprite = Sprite2D.new()
	ghost_sprite.modulate = Color(1, 1, 1, 0.5) 
	ghost_sprite.visible = false
	add_child(ghost_sprite)

	if selector:
		selector.deck_confirmed.connect(_on_deck_confirmed)
		get_tree().paused = true 
	else:
		print("Advertencia: No hay DeckSelector...")
	
	if spawner:
		spawner.wave_started.connect(_on_wave_started)
		if spawner.has_signal("wave_completed"):
			spawner.wave_completed.connect(_on_wave_completed)
		if spawner.has_signal("level_time_finished"):
			spawner.level_time_finished.connect(_on_level_time_finished)
	else:
		print("No se encontro el spawner de enemigos")
		
	if hud_timer_panel:
		var style = hud_timer_panel.get_theme_stylebox("panel")
		if style:
			hud_timer_panel.add_theme_stylebox_override("panel", style.duplicate())
	
	print("🔴 GameManager INICIADO. ID de Instancia: ", get_instance_id())

func _on_wave_started(wave: int):
	is_game_over_processing = false
	if wave_label:
		wave_label.text = "Wave " + str(wave)
		
func _on_deck_confirmed(selected_deck: Array[HeroData]):
	print("Mazo confirmado con: ", selected_deck.size(), " cartas.")
	var hand_container = $UI/Hand
	for child in hand_container.get_children(): child.queue_free()
	
	for data in selected_deck:
		if card_ui_scene:
			var new_card = card_ui_scene.instantiate()
			hand_container.add_child(new_card)
			new_card.setup(data)
			new_card.drag_started.connect(_on_card_drag_started)
			new_card.drag_ended.connect(_on_card_drag_ended)
		else:
			print("ERROR: No has asignado card_ui_scene en el GameManager")

	get_tree().paused = false

func _process(_delta):
	if current_energy < max_energy:
		energy_timer += _delta
		if energy_timer >= energy_regen_rate:
			energy_timer = 0.0
			current_energy += 1
			energy_updated.emit(current_energy, max_energy)
	
	if is_dragging and current_card:
		ghost_sprite.global_position = get_global_mouse_position()
		var can_afford = current_energy >= current_card.cost
		var valid_zone = is_valid_drop_zone(ghost_sprite.global_position)
		
		if valid_zone and can_afford:
			ghost_sprite.modulate = Color(0, 1, 0, 0.5) 
		elif not can_afford:
			ghost_sprite.modulate = Color(0, 0, 1, 0.5) 
		else:
			ghost_sprite.modulate = Color(1, 0, 0, 0.5) 
			
	update_timer_display()

func update_timer_display():
	if not is_normal_mode or not spawner or not spawner.level_timer:
		if hud_timer_panel: hud_timer_panel.hide()
		return
	
	hud_timer_panel.show()
	var time_left = spawner.level_timer.time_left
	
	if spawner.level_timer.is_stopped() and spawner.current_wave > 0:
		wave_time.text = "Time left: --"
	else:
		wave_time.text = "Time left: %d s" % int(time_left)
	
	var style = hud_timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		if time_left <= warning_time_threshold and time_left > 0:
			style.border_color = Color.RED
			style.set_border_width_all(4)
		else:
			style.border_color = Color.TRANSPARENT
			style.set_border_width_all(2)
			
func _on_card_drag_started(data: HeroData):
	if data == null: return
	current_card = data
	is_dragging = true
	ghost_sprite.texture = data.icon
	ghost_sprite.visible = true

func _on_card_drag_ended(data: HeroData):
	is_dragging = false
	ghost_sprite.visible = false
	var drop_pos = get_global_mouse_position()
	var enemy = get_closest_enemy(drop_pos)

	if is_valid_drop_zone(drop_pos) and enemy != null:
		if current_energy >= data.cost:
			current_energy -= data.cost
			energy_updated.emit(current_energy, max_energy)
			spawn_unit(data, drop_pos, enemy)
		else:
			print("No tienes suficiente energía.")
	else:
		print("Zona inválida o no hay enemigos cerca")
		
func is_valid_drop_zone(pos: Vector2) -> bool:
	return (pos.y > 440 && pos.y < 980) && (pos.x > 0 && pos.x < 1000)

func spawn_unit(data: HeroData, pos: Vector2, target: CharacterBody2D):
	if data.unit_scene:
		var new_unit = data.unit_scene.instantiate()
		new_unit.global_position = pos
		$Heroes.add_child(new_unit)
		new_unit.initialize(data, target)
	else:
		print("ERROR: El recurso .tres no tiene asignada una Escena")

func add_experience(amount: int):
	if is_game_over_processing: return
	current_xp += amount
	xp_updated.emit(current_xp)
	if xp_label: xp_label.text = "XP points: " + str(current_xp)

func get_xp_icon_position() -> Vector2:
	if xp_ui_icon: return xp_ui_icon.get_global_rect().get_center()
	return Vector2(50, 50)

func upgrade_hero_type(data: HeroData):
	var cost = calculate_upgrade_cost(data)
	if current_xp >= cost:
		current_xp -= cost
		xp_updated.emit(current_xp)
		if xp_label: xp_label.text = "XP points: " + str(current_xp)
		
		var hero_name = data.name
		if not hero_levels.has(hero_name): hero_levels[hero_name] = 1
		hero_levels[hero_name] += 1
		hero_level_changed.emit(hero_name, hero_levels[hero_name])
		
		data.health = int(data.health * 1.2)
		data.attack = int(data.attack * 1.2)
		
		var heroes = get_tree().get_nodes_in_group("heroGroup")
		for hero in heroes:
			if "name" in hero and hero.name == hero_name:
				if hero.has_method("apply_upgrade"):
					hero.apply_upgrade()
				
func _on_endless_pressed():
	if spawner: spawner.require_clear_wave = false
	if endless_btn: endless_btn.modulate = Color(0, 1, 0) 
	if normal_btn: normal_btn.modulate = Color(1, 1, 1)  
	is_normal_mode = false
	
func _on_normal_pressed():
	if spawner: spawner.require_clear_wave = true
	if normal_btn: normal_btn.modulate = Color(0, 0.5, 1)  
	if endless_btn: endless_btn.modulate = Color(1, 1, 1) 
	is_normal_mode = true
	
func calculate_upgrade_cost(data: HeroData) -> int:
	var current_lvl = hero_levels.get(data.name, 1)
	return current_lvl * 30 

func register_drop(data):
	print("🔵 [ID: ", get_instance_id(), "] INTENTO DE REGISTRO DE DROP")
	print("Datos recibidos: ", data)
	
	var item_to_save: ItemData = null

	# 1. Comprobar si es el Recurso directo
	if data is ItemData:
		print(">> Es un ItemData válido.")
		item_to_save = data
	
	# 2. Comprobar si es un envoltorio (Wrapper o Nodo)
	elif "item_data" in data:
		print(">> Es un objeto contenedor.")
		if data.item_data is ItemData:
			print(">> Contiene un ItemData válido dentro.")
			item_to_save = data.item_data
		else:
			print("!! ERROR: Tiene propiedad 'item_data' pero es: ", data.item_data)
	else:
		print("!! ERROR: Los datos no son ItemData ni tienen propiedad item_data.")

	# 3. Guardado
	if item_to_save:
		current_wave_loot.append(item_to_save)
		# Guardamos en inventario global (si existe PlayerData)
		if PlayerData:
			PlayerData.add_item_to_bag(item_to_save)
		
		print(">> ÉXITO. Total items en este Manager: ", current_wave_loot.size())
	else:
		print("!! FALLO: No se pudo extraer un ItemData para guardar.")
	print("-------------------------------------")

func _on_wave_completed():
	if is_normal_mode:
		show_wave_summary(false)
	else:
		if spawner and spawner.has_method("start_next_wave"):
			spawner.start_next_wave()

func _on_level_time_finished():
	is_game_over_processing = true 
	if has_method("clear_living_enemies"): call("clear_living_enemies")
	clean_arena_items()
	if is_normal_mode: show_wave_summary(true)

func show_wave_summary(is_final_game: bool = false):
	print("🟠 [ID: ", get_instance_id(), "] MOSTRANDO RESUMEN DE OLA")
	print("Items en la lista a enviar a UI: ", current_wave_loot.size())
	
	if reward_ui_scene:
		var window = reward_ui_scene.instantiate()
		$UI.add_child(window)
		
		# Pasamos los datos
		window.set_loot_data(current_wave_loot)
		window.set_mode(is_final_game)
		
		window.continue_pressed.connect(_on_summary_closed)
		window.exit_with_loot_requested.connect(_on_game_exit_requested)
	else:
		print("ERROR: reward_ui_scene no asignada en Inspector")
		_on_summary_closed()

func _on_summary_closed():
	current_wave_loot.clear()
	clean_arena_items()
	if spawner and spawner.has_method("start_next_wave"):
		spawner.start_next_wave()
	
func clean_arena_items():
	var visual_items = get_tree().get_nodes_in_group("dropped_items")
	for item in visual_items: item.queue_free()
	
func _on_game_exit_requested():
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu.tscn")

func clear_living_enemies():
	var active_enemies = get_tree().get_nodes_in_group("enemyGroup")
	for enemy in active_enemies:
		if enemy.has_method("despawn_without_reward"):
			enemy.despawn_without_reward()
		else:
			enemy.queue_free()

func roll_rarity_from_weights(weights: Array) -> int:
	var roll = randi() % 100 + 1 
	var cumulative = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative: return i
	return 0 
	
func get_current_wave_rarity() -> String:
	# Claves en Inglés para coincidir con RARITY_COLORS
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var wave = 1
	if spawner and "current_wave" in spawner:
		wave = spawner.current_wave
	
	var weights = []
	if wave <= 15: weights = [70, 30, 0, 0, 0]
	elif wave <= 30: weights = [60, 35, 5, 0, 0]
	elif wave <= 45: weights = [50, 40, 10, 0, 0]
	elif wave <= 60: weights = [40, 40, 17, 3, 0]
	elif wave <= 75: weights = [30, 45, 21, 3, 1]
	elif wave <= 85: weights = [20, 35, 35, 8, 2]
	else: weights = [10, 30, 40, 18, 2]
		
	var rarity_index = roll_rarity_from_weights(weights)
	return rarity_names[rarity_index]
