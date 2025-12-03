extends Node2D

@export var valid_spawn_area: Rect2 # Define un área donde se puede invocar (o usa un Area2D)
@export var card_ui_scene: PackedScene

signal xp_updated(new_amount: int)
signal hero_level_changed(hero_name: String, new_level: int)

var current_xp: int = 0
var current_card: HeroData = null
var ghost_sprite: Sprite2D # El visual transparente
var is_dragging: bool = false
# Referencia visual a donde volarán las orbes de exp (ej. un icono en la esquina)
@onready var xp_ui_icon = $UI/XP_Counter/Icon
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
	if is_dragging and current_card:
		# El fantasma sigue al mouse
		ghost_sprite.global_position = get_global_mouse_position()
		
		# Feedback visual: ¿Es zona válida? (Simple chequeo de Y)
		if is_valid_drop_zone(ghost_sprite.global_position):	
			ghost_sprite.modulate = Color(0, 1, 0, 0.5) # Verde
		else:
			ghost_sprite.modulate = Color(1, 0, 0, 0.5) # Rojo

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
	if is_valid_drop_zone(drop_pos) && enemy != null:
		print("Data es ",data," posicion es ",drop_pos," el enemigo es ", enemy)
		spawn_unit(data, drop_pos, enemy)
		
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
	current_xp += amount
	print("XP Total: ", current_xp)
	xp_updated.emit(current_xp)

func get_xp_icon_position() -> Vector2:
	if has_node("UI/XP_Counter/Icon"):
		return $UI/XP_Counter/Icon.get_global_rect().get_center()
	return Vector2(100, 100) # Default por si acaso

# Función para subir de nivel
func upgrade_hero_type(data: HeroData):
	var cost = calculate_upgrade_cost(data)
	
	if current_xp >= cost:
		current_xp -= cost
		xp_updated.emit(current_xp)
		print("Experiencia restante ...", current_xp)
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
		data.damage = int(data.damage * 1.2)
		
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

func calculate_upgrade_cost(data: HeroData) -> int:
	# Lógica simple: Nivel actual * 100. 
	var current_lvl = hero_levels.get(data.name, 1)
	return current_lvl * 30 # Ejemplo: Nivel 1 cuesta 30, Nivel 2 cuesta 60
