extends Node2D

@export var valid_spawn_area: Rect2 # Define un área donde se puede invocar (o usa un Area2D)

var current_card: CardData = null
var ghost_sprite: Sprite2D # El visual transparente
var is_dragging: bool = false
var closest_enemy = null

func get_closest_enemy():
	var shortest_distance = INF
	var enemies = get_tree().get_nodes_in_group("enemyGroup")

	for enemy in enemies:
		if enemy == null:
			continue
		var distance = global_position.distance_to(enemy.global_position)
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
	
	var card_node = $UI/Hand/CardUI	
	# Conectar señales de las cartas (esto hazlo en el editor o por código)
	#$UI/Hand/CardUI.card_selected.connect(_on_card_selected)
	
	if card_node:
		# Conectamos las señales definidas en CardUI.gd
		card_node.drag_started.connect(_on_card_drag_started)
		card_node.drag_ended.connect(_on_card_drag_ended)
		print("Señales conectadas correctamente")
	else:
		print("ERROR FATAL: No encuentro el nodo CardUI. Revisa la ruta en GameManager.gd")

func _process(_delta):
	if is_dragging and current_card:
		# El fantasma sigue al mouse
		ghost_sprite.global_position = get_global_mouse_position()
		
		# Feedback visual: ¿Es zona válida? (Simple chequeo de Y)
		if is_valid_drop_zone(ghost_sprite.global_position):	
			ghost_sprite.modulate = Color(0, 1, 0, 0.5) # Verde
		else:
			ghost_sprite.modulate = Color(1, 0, 0, 0.5) # Rojo

func _on_card_drag_started(data: CardData):
	print("Drag iniciado recibido en Manager")
	if data == null:
		print("ERROR: La carta no tiene datos (Card Data está vacío)")
		return
		
	current_card = data
	is_dragging = true
	ghost_sprite.texture = data.icon
	ghost_sprite.visible = true

func _on_card_drag_ended(data: CardData):
	print("Drag terminado")
	is_dragging = false
	ghost_sprite.visible = false
	
	var drop_pos = get_global_mouse_position()
	var enemy = get_closest_enemy()
	
	if is_valid_drop_zone(drop_pos) && enemy != null:
		print("Data es ",data," posicion es ",drop_pos," el enemigo es ", enemy)
		spawn_unit(data, drop_pos, enemy)
		
func is_valid_drop_zone(pos: Vector2) -> bool:
	# Ejemplo simple: Solo puedes invocar en la mitad inferior de la pantalla
	# Ajusta este valor según el tamaño de tu arena
	return pos.y > 300

func spawn_unit(data: CardData, pos: Vector2, target: CharacterBody2D):
	if data.unit_scene:
		var new_unit = data.unit_scene.instantiate()
		new_unit.global_position = pos
		$Heroes.add_child(new_unit)
		new_unit.initialize(data, target)
		print("Unidad creada")
	else:
		print("ERROR: El recurso .tres no tiene asignada una Escena (Unit Scene)")
