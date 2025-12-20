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
	var groups = {} # Diccionario: { "NombreItem": { "count": 0, "item_ref": Resource } }
	
	for drop in loot_list:
		# Extraemos el ItemData real (desempaquetando el DropData si es necesario)
		var item = drop
		if "item_data" in drop and drop.item_data:
			item = drop.item_data
			
		if item == null: continue
		
		# Usamos el NOMBRE como clave.
		# Así, dos botas distintas con stats distintos se agruparán si se llaman igual.
		var key_name = item.name 
		
		if not groups.has(key_name):
			groups[key_name] = {
				"count": 1,
				"item_ref": item # Guardamos una referencia para sacar el icono luego
			}
		else:
			groups[key_name]["count"] += 1

	# 3. Dibujar los items agrupados
	for key_name in groups:
		var data = groups[key_name]
		var count = data["count"]
		var item_ref = data["item_ref"] # Usamos el primero que encontramos para la foto
		
		# --- A partir de aquí es tu código visual de siempre ---
		var slot = VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(64, 64)
		
		var icon_rect = TextureRect.new()
		if item_ref.icon:
			icon_rect.texture = item_ref.icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT) 
		icon_container.add_child(icon_rect)
		
		# Indicador de Multiplicador
		if count > 1:
			var count_lbl = Label.new()
			count_lbl.text = " x " + str(count)
			count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_lbl.position = Vector2(-4, -4)
			count_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			count_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
			count_lbl.modulate = Color(1, 1, 0)
			count_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			count_lbl.add_theme_constant_override("outline_size", 6)
			count_lbl.add_theme_font_size_override("font_size", 20)
			icon_container.add_child(count_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = item_ref.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
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
