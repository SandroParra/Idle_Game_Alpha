extends Node2D

@export var enemy_tower: Node2D
@export var valid_spawn_area: Rect2 # Define un área donde se puede invocar (o usa un Area2D)

var current_card: CardData
var ghost_sprite: Sprite2D # El visual transparente
var is_dragging: bool = false

func _ready():
	# Crear el sprite fantasma dinámicamente
	ghost_sprite = Sprite2D.new()
	ghost_sprite.modulate = Color(1, 1, 1, 0.5) # Semitransparente
	ghost_sprite.visible = false
	add_child(ghost_sprite)
	
	# Conectar señales de las cartas (esto hazlo en el editor o por código)
	$CanvasLayer/Hand/CardUI.card_selected.connect(_on_card_selected)

func _process(_delta):
	if is_dragging and current_card:
		# El fantasma sigue al mouse
		ghost_sprite.global_position = get_global_mouse_position()
		
		# Feedback visual: ¿Es zona válida? (Simple chequeo de Y)
		if is_valid_drop_zone(ghost_sprite.global_position):
			ghost_sprite.modulate = Color(0, 1, 0, 0.5) # Verde
		else:
			ghost_sprite.modulate = Color(1, 0, 0, 0.5) # Rojo

	# Detectar soltar clic para invocar
	if is_dragging and Input.is_action_just_released("mouse_left"):
		end_drag()

func _on_card_selected(data: CardData):
	current_card = data
	ghost_sprite.texture = data.icon # O usa una textura de la unidad
	ghost_sprite.visible = true
	is_dragging = true

func end_drag():
	var drop_pos = get_global_mouse_position()
	
	if is_valid_drop_zone(drop_pos):
		spawn_unit(drop_pos)
	
	# Resetear estado
	is_dragging = false
	current_card = null
	ghost_sprite.visible = false

func is_valid_drop_zone(pos: Vector2) -> bool:
	# Ejemplo simple: Solo puedes invocar en la mitad inferior de la pantalla
	# Ajusta este valor según el tamaño de tu arena
	return pos.y > 300 

func spawn_unit(pos: Vector2):
	var new_unit = current_card.unit_scene.instantiate()
	# Añadimos la unidad al contenedor "YSort" para profundidad correcta
	$UnitsContainer.add_child(new_unit) 
	new_unit.global_position = pos
	new_unit.initialize(current_card, enemy_tower)	
