extends Node2D

@export var valid_spawn_area: Rect2 # Define un área donde se puede invocar (o usa un Area2D)
@export var card_ui_scene: PackedScene
@export var reward_ui_scene: PackedScene
@export var warning_time_threshold: float = 10.0 # Segundos para que se ponga rojo (X tiempo)

@export_group("Energy System")
@export var max_energy: int = 30
@export var energy_regen_rate: float = 2.0 # Segundos para ganar 1 punto
@export var starting_energy: int = 5 # Energía inicial al empezar la partida

signal xp_updated(new_amount: int)
signal hero_level_changed(hero_name: String, new_level: int)
signal energy_updated(current: int, max_amount: int)

var current_xp: int = 0
var current_card: HeroData = null
var current_energy: int = 0
var energy_timer: float = 0.0
var ghost_sprite: Sprite2D # El visual transparente
var is_dragging: bool = false
var current_wave_loot: Array[DropData] = []
var is_normal_mode: bool = true # Para saber si mostramos la ventana o no
var is_game_over_processing: bool = false

# Referencia visual a donde volarán las orbes de exp (ej. un icono en la esquina)
@onready var xp_ui_icon = $UI/XP_Counter/Icon
@onready var xp_label = $UI/XP_Counter/XP_Label
#@onready var wave_label = $UI/Wave_Counter/Wave_Label
@onready var endless_btn = $UI/EndlessBtn
@onready var normal_btn = $UI/NormalBtn
@onready var spawner = $Enemies/enemySpawner

@onready var hud_timer_panel = $UI/HUD_Timer
@onready var wave_label = $UI/HUD_Timer/VBoxContainer/Wave_Label
@onready var wave_time = $UI/HUD_Timer/VBoxContainer/Wave_Time
@onready var energy_ui = $UI/EnergyBar


# Diccionario para guardar el nivel actual de cada tipo de héroe
# Ejemplo: { "BlackDragon": 1, "MaleViking": 2 }
var hero_levels: Dictionary = {}

func get_closest_enemy(reference_position: Vector2)->CharacterBody2D:
	var closest_enemy = null
	var shortest_distance = INF
	var enemies = get_tree().get_nodes_in_group("enemyGroup")

# Si no hay enemigos, retornamos null rápido
	if enemies.is_empty():
		return null
		
	for enemy in enemies:
		if enemy == null:
			continue
			
		var distance = reference_position.distance_to(enemy.global_position)
		#var distance = abs(global_position.distance_to(enemy.global_position))
		if distance < shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy
	return closest_enemy
	
func _ready():
	current_energy = starting_energy
	
	if energy_ui and energy_ui.has_method("update_bar"):
		# Conectamos nuestra señal lógica a la función visual
		energy_updated.connect(energy_ui.update_bar)
	else:
		print("ERROR: No se encontró EnergyBar o le falta el script")
		
	# Emitir señal inicial para que la UI empiece correcta
	energy_updated.emit(current_energy, max_energy)
	
	endless_btn.pressed.connect(_on_endless_pressed)
	normal_btn.pressed.connect(_on_normal_pressed)
	
	# Crear el sprite fantasma dinámicamente
	ghost_sprite = Sprite2D.new()
	ghost_sprite.modulate = Color(1, 1, 1, 0.5) # Semitransparente
	ghost_sprite.visible = false
	add_child(ghost_sprite)
		
	# 1. Buscamos el selector
	var selector = $UI/DeckSelector
	if selector:
		# Conectamos su señal
		selector.deck_confirmed.connect(_on_deck_confirmed)
		# Pausamos el juego si quieres que no corra el tiempo mientras elige
		get_tree().paused = true 
	else:
		print("Advertencia: No hay DeckSelector, esperando cartas manuales...")
	
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

func _on_wave_started(wave: int):
	is_game_over_processing = false
	# Actualizar el nuevo label del HUD central
	if wave_label:
		wave_label.text = "Wave " + str(wave)
		
func _on_deck_confirmed(selected_deck: Array[HeroData]):
	print("Mazo confirmado con: ", selected_deck.size(), " cartas.")
	
	var hand_container = $UI/Hand
	
	# 1. Limpiar mano por si acaso
	for child in hand_container.get_children():
		child.queue_free()
	
	# 2. Crear las cartas visuales
	for data in selected_deck:
		if card_ui_scene:
			var new_card = card_ui_scene.instantiate()
			hand_container.add_child(new_card)
			
			# IMPORTANTE: Asignar los datos a la carta
			# Asumimos que CardUI tiene una variable 'data' y un _ready que carga el icono
			#new_card.data = data 
			new_card.setup(data)
			# 3. Conectar señales (Igual que antes pero ahora dinámico)
			new_card.drag_started.connect(_on_card_drag_started)
			new_card.drag_ended.connect(_on_card_drag_ended)
		else:
			print("ERROR: No has asignado card_ui_scene en el GameManager")

	# Si pausaste el juego, despausalo aquí:
	get_tree().paused = false

func _process(_delta):
	if current_energy < max_energy:
		energy_timer += _delta
		if energy_timer >= energy_regen_rate:
			energy_timer = 0.0
			current_energy += 1
			# Emitimos señal para que la UI se entere
			energy_updated.emit(current_energy, max_energy)
			print("Energía regenerada: ", current_energy) # Debug
	
	if is_dragging and current_card:
		ghost_sprite.global_position = get_global_mouse_position()
		
		# Validamos zona Y TAMBIÉN si tenemos energía suficiente
		var can_afford = current_energy >= current_card.cost
		var valid_zone = is_valid_drop_zone(ghost_sprite.global_position)
		
		if valid_zone and can_afford:
			ghost_sprite.modulate = Color(0, 1, 0, 0.5) # Verde: Todo OK
		elif not can_afford:
			ghost_sprite.modulate = Color(0, 0, 1, 0.5) # Azul/Gris: Zona válida pero falta energía
		else:
			ghost_sprite.modulate = Color(1, 0, 0, 0.5) # Rojo: Zona inválida
			
	update_timer_display()

func update_timer_display():
	# Si no estamos en modo normal o no hay spawner, ocultamos el panel
	if not is_normal_mode or not spawner or not spawner.level_timer:
		if hud_timer_panel: hud_timer_panel.hide()
		return
	
	hud_timer_panel.show()
	
	# 1. Obtener tiempo restante del Spawner
	# Asegúrate de que el Timer no esté detenido para no mostrar 0 cuando no toca
	var time_left = spawner.level_timer.time_left
	
	# Solo mostramos tiempo si el timer está corriendo
	if spawner.level_timer.is_stopped() and spawner.current_wave > 0:
		# Opcional: Mostrar 0 o el último valor
		wave_time.text = "Time left: --"
	else:
		wave_time.text = "Time left: %d s" % int(time_left)
	
	# 2. Lógica del Borde Rojo
	var style = hud_timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		if time_left <= warning_time_threshold and time_left > 0:
			style.border_color = Color.RED
			# Opcional: Hacerlo pulsar o más grueso
			style.set_border_width_all(4)
		else:
			style.border_color = Color.TRANSPARENT # O blanco si prefieres
			style.set_border_width_all(2)
			
func _on_card_drag_started(data: HeroData):
	print("Drag iniciado recibido en Manager")
	if data == null:
		print("ERROR: La carta no tiene datos (Card Data está vacío)")
		return
		
	current_card = data
	is_dragging = true
	ghost_sprite.texture = data.icon
	ghost_sprite.visible = true

func _on_card_drag_ended(data: HeroData):
	print("Drag terminado")
	is_dragging = false
	ghost_sprite.visible = false
	
	var drop_pos = get_global_mouse_position()
	var enemy = get_closest_enemy(drop_pos)
	print("closest enemy is ... ", enemy)

	if is_valid_drop_zone(drop_pos) and enemy != null:
		if current_energy >= data.cost:
			# A. Restamos la energía
			current_energy -= data.cost
			energy_updated.emit(current_energy, max_energy)
			
			# B. Invocamos
			spawn_unit(data, drop_pos, enemy)
			print("Unidad invocada. Energía restante: ", current_energy)
		else:
			print("No tienes suficiente energía. Costo: ", data.cost, " / Actual: ", current_energy)
			# Aquí podrías poner un sonido de error o un "shake" en la UI
	else:
		print("Zona inválida o no hay enemigos cerca")
		
func is_valid_drop_zone(pos: Vector2) -> bool:
	# Solo se puede invocar en la mitad inferior de la pantalla
	return (pos.y > 440 && pos.y < 980) && (pos.x > 0 && pos.x < 1000)

func spawn_unit(data: HeroData, pos: Vector2, target: CharacterBody2D):
	if data.unit_scene:
		var new_unit = data.unit_scene.instantiate()
		new_unit.global_position = pos
		$Heroes.add_child(new_unit)
		new_unit.initialize(data, target)
		print("Unidad creada")
	else:
		print("ERROR: El recurso .tres no tiene asignada una Escena (Unit Scene)")

func add_experience(amount: int):
	# Si el juego está terminando, ignoramos la experiencia que llegue volando
	if is_game_over_processing: return
		
	current_xp += amount
	print("XP Total: ", current_xp)
	xp_updated.emit(current_xp)
	xp_label.text = "XP points: " + str(current_xp)

func get_xp_icon_position() -> Vector2:
	# Asegúrate que la ruta al icono sea correcta en tu escena
	var icon = $UI/XP_Counter/Icon
	if icon:
		# get_global_rect().get_center() nos da el centro exacto del icono en pantalla
		return icon.get_global_rect().get_center()
	return Vector2(50, 50)

# Función para subir de nivel
func upgrade_hero_type(data: HeroData):
	var cost = calculate_upgrade_cost(data)
	
	if current_xp >= cost:
		current_xp -= cost
		xp_updated.emit(current_xp)
		print("Experiencia restante ...", current_xp)
		xp_label.text = "XP points: " + str(current_xp)
		# 1. Registrar subida de nivel
		var hero_name = data.name
		if not hero_levels.has(hero_name):
			hero_levels[hero_name] = 1
		hero_levels[hero_name] += 1
		hero_level_changed.emit(hero_name, hero_levels[hero_name])
		print("¡Mejorando ", hero_name, " a Nivel ", hero_levels[hero_name], "!")
		
		# 2. Mejorar la CARTA ORIGINAL (para futuros spawns)
		# Aumentamos stats base un 20% por ejemplo
		data.health = int(data.health * 1.2)
		data.attack = int(data.attack * 1.2)
		
		# 3. Mejorar las UNIDADES YA VIVAS en el mapa
		var heroes = get_tree().get_nodes_in_group("heroGroup")
		for hero in heroes:
			# Verificamos si este héroe es del tipo que estamos mejorando
			if "name" in hero:
				if hero.name == hero_name:
					# Verificar que tenga el método antes de llamarlo
					if hero.has_method("apply_upgrade"):
						hero.apply_upgrade()
			else:
				# Debug opcional: Saber qué nodo falló
				print("Advertencia: Se encontró un nodo en heroGroup sin unit_name: ", hero.name)
				
func _on_endless_pressed():
	if spawner:
		spawner.require_clear_wave = false
		print("Switched to Endless Mode")
		
		endless_btn.modulate = Color(0, 1, 0) 
		normal_btn.modulate = Color(1, 1, 1)  
	is_normal_mode = false
	
func _on_normal_pressed():
	if spawner:
		spawner.require_clear_wave = true
		print("Switched to Normal Mode")
		
		normal_btn.modulate = Color(0, 0.5, 1)  
		endless_btn.modulate = Color(1, 1, 1) 
	is_normal_mode = true
	
func calculate_upgrade_cost(data: HeroData) -> int:
	# Lógica simple: Nivel actual * 100. 
	var current_lvl = hero_levels.get(data.name, 1)
	return current_lvl * 30 # Ejemplo: Nivel 1 cuesta 30, Nivel 2 cuesta 60

func register_drop(data: DropData):
	print("Item recolectado: ", data.item_data.name)
	current_wave_loot.append(data)

func _on_wave_completed():
	if is_normal_mode:
		show_wave_summary(false) # false = NO es el final, muestra "Continuar"
	else:
		if spawner and spawner.has_method("start_next_wave"):
			spawner.start_next_wave()

func _on_level_time_finished():
	is_game_over_processing = true # <--- ACTIVAMOS EL BLOQUEO
	# Llamamos a limpiar enemigos (la función que hicimos antes)
	if has_method("clear_living_enemies"):
		call("clear_living_enemies")
	
	clean_arena_items()
	
	if is_normal_mode:
		show_wave_summary(true)

func show_wave_summary(is_final_game: bool = false):
	if reward_ui_scene:
		var window = reward_ui_scene.instantiate()
		$UI.add_child(window) # O add_child(window) directo
		
		# Pasamos los datos
		window.set_loot_data(current_wave_loot)
		window.set_mode(is_final_game)
		
		# Conectamos el botón de continuar para iniciar la siguiente ola
		window.continue_pressed.connect(_on_summary_closed)
		window.exit_with_loot_requested.connect(_on_game_exit_requested)
	else:
		print("ERROR: No has asignado reward_ui_scene en GameManager")
		_on_summary_closed()

func _on_summary_closed():
	# 1. GUARDAR LOOT EN INVENTARIO GLOBAL
	print("Guardando ", current_wave_loot.size(), " items en el inventario...")
	process_current_loot()
	# 2. Limpiamos la lista para la nueva ola
	current_wave_loot.clear()
	clean_arena_items()
	
	# 3. Decimos al spawner que arranque la siguiente
	if spawner and spawner.has_method("start_next_wave"):
		spawner.start_next_wave()
	
func clean_arena_items():
	# Buscamos todos los nodos que metimos en el grupo "dropped_items"
	var visual_items = get_tree().get_nodes_in_group("dropped_items")
	
	for item in visual_items:
		item.queue_free()
	
	print("Arena limpiada: ", visual_items.size(), " items eliminados.")


func process_current_loot():
	print("Procesando loot antes de salir/continuar...")
	for drop in current_wave_loot:
		if drop.item_data:
			PlayerData.add_item_to_bag(drop.item_data)
			print("Guardado item real: ", drop.item_data.name)
	# Guardamos inmediatamente en disco para no perder nada
	PlayerData.save_game()
	
func _on_game_exit_requested():
	# 1. Guardamos los items de ESTA ola
	process_current_loot()
	
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu.tscn")

func clear_living_enemies():
	# Obtenemos todos los nodos del grupo "enemyGroup" definido en EnemyUnit [cite: 3]
	var active_enemies = get_tree().get_nodes_in_group("enemyGroup")
	
	for enemy in active_enemies:
		# Verificamos si tienen el nuevo método para borrarlos limpiamente
		if enemy.has_method("despawn_without_reward"):
			enemy.despawn_without_reward()
		else:
			# Fallback por seguridad
			enemy.queue_free()
