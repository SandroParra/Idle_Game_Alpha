extends CanvasLayer

signal exit_with_loot_requested
signal continue_pressed


@export var grid: Container 
@onready var continue_btn = $Panel/VBoxContainer/ContinueButton
@onready var exit_btn = $Panel/VBoxContainer/ExitButton

var loot_list: Array = []

func _ready():
	if not continue_btn:
		printerr("ERROR CRÍTICO: No se encuentra 'ContinueButton' en WaveRewardUI inside Panel/VBoxContainer")
	if not exit_btn:
		printerr("ERROR CRÍTICO: No se encuentra 'ExitButton' en WaveRewardUI.")
		
	if grid == null:
		print("ERROR FATAL: No has asignado el nodo ItemGrid en el Inspector de WaveRewardUI")
		return
		
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)
		exit_btn.hide()
		
	get_tree().paused = true
	
	# Si set_loot_data se llamó antes del _ready, mostramos los datos ahora
	if not loot_list.is_empty():
		display_loot()
		
func set_mode(is_final_wave: bool):
	if is_final_wave:
		if continue_btn: continue_btn.hide()
		if exit_btn: exit_btn.show()
	else:
		if continue_btn: continue_btn.show()
		if exit_btn: exit_btn.show()

func set_loot_data(items: Array):
	loot_list = items.duplicate()
	
	#Solo pintamos si el nodo ya está listo ---
	if is_node_ready() and grid:
		display_loot()

func display_loot():
	# 1. Limpiar la grilla anterior
	for child in grid.get_children():
		child.queue_free()
	
	if loot_list.is_empty():
		var label = Label.new()
		label.text = "Sin recompensas..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(label)
		return

	# 2. Agrupar items (Lógica de conteo)
	var item_counts = {}   # Diccionario { ItemData : Cantidad }
	var unique_items = []  # Lista para mantener el orden en que aparecieron
	
	for drop in loot_list:
		# Determinamos qué objeto usar como clave (el ItemData real o el drop antiguo)
		var key = drop.item_data if ("item_data" in drop and drop.item_data) else drop
		
		if not item_counts.has(key):
			item_counts[key] = 1
			unique_items.append(key)
		else:
			item_counts[key] += 1

	# 3. Dibujar los items agrupados
	for item in unique_items:
		var count = item_counts[item]
		
		# Slot vertical (Icono arriba, Nombre abajo)
		var slot = VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# --- Contenedor para el icono (permite superponer el texto x4) ---
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(64, 64) # Tamaño fijo para el icono
		
		# El Icono
		var icon_rect = TextureRect.new()
		if item.icon:
			icon_rect.texture = item.icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Hacer que el icono llene el contenedor
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT) 
		icon_container.add_child(icon_rect)
		
		# --- El Indicador de Multiplicador (SOLO SI HAY MÁS DE 1) ---
		if count > 1:
			var count_lbl = Label.new()
			count_lbl.text = " x " + str(count)
			
			# Posicionar abajo a la derecha
			count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_lbl.position = Vector2(-4, -4) # Un pequeño margen desde la esquina
			count_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			count_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
			
			# Estilo para que resalte (Texto amarillo con borde negro)
			count_lbl.modulate = Color(1, 1, 0) # Amarillo
			count_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			count_lbl.add_theme_constant_override("outline_size", 6)
			count_lbl.add_theme_font_size_override("font_size", 20) # Ajusta el tamaño a tu gusto
			
			icon_container.add_child(count_lbl)
		# -------------------------------------------------------------
		
		# Nombre del item
		var name_lbl = Label.new()
		if "name" in item:
			name_lbl.text = item.name
		else:
			name_lbl.text = "Item"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Añadir todo al slot y luego a la grilla
		slot.add_child(icon_container)
		slot.add_child(name_lbl)
		grid.add_child(slot)

func _on_continue_pressed():
	get_tree().paused = false
	continue_pressed.emit()
	queue_free()

func _on_exit_pressed():
	get_tree().paused = false
	# Regresar al Menú Principal
	exit_with_loot_requested.emit()
	queue_free()
