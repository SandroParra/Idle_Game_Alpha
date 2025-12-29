extends CanvasLayer

signal exit_with_loot_requested
signal continue_pressed

@export var grid: Container 
@onready var continue_btn = $Panel/ContinueBtn/ContinueButton
@onready var exit_btn = $Panel/ExitBtn/ExitButton

# Diccionario de colores para el texto
const RARITY_COLORS = {
	"Common": Color("#b0b0b0"),    # Gris
	"Uncommon": Color("#44bd32"),  # Verde
	"Rare": Color("#00a8ff"),      # Azul
	"Epic": Color("#8c7ae6"),      # Morado
	"Legendary": Color("#f1c40f")  # Dorado
}

var loot_list: Array = []

func _ready():
	if not continue_btn:
		printerr("ERROR CRÍTICO: No se encuentra 'ContinueButton' en WaveRewardUI inside Panel/")
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
	var groups = {} 
	
	for drop in loot_list:
		var item = drop
		if "item_data" in drop and drop.item_data:
			item = drop.item_data
			
		if item == null: continue
		
		# Usamos un valor por defecto "Common" si no tiene rareza definida
		var rarity_val = "Common"
		if "rarity" in item: rarity_val = item.rarity
		
		var key_unique = rarity_val + "_" + item.name 
		
		if not groups.has(key_unique):
			groups[key_unique] = {
				"count": 1,
				"item_ref": item,
				"rarity": rarity_val # Guardamos la rareza para usarla fácil luego
			}
		else:
			groups[key_unique]["count"] += 1

	# 3. Dibujar los items agrupados
	for key in groups:
		var data = groups[key]
		var count = data["count"]
		var item_ref = data["item_ref"]
		var rarity_str = data["rarity"]
		
		var slot = VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		# Un poco de separación entre slots si es necesario
		slot.add_theme_constant_override("separation", 5)
		
		# --- ICONO ---
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(40, 40)
		icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER # Centrar icono
		
		var icon_rect = TextureRect.new()
		if item_ref.icon:
			icon_rect.texture = item_ref.icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT) 
		icon_container.add_child(icon_rect)
		
		# (Opcional) He quitado el contador superpuesto en el icono 
		# porque ahora lo pediste explícitamente en el texto de abajo.
		
		# --- ETIQUETA DE TEXTO ---
		var name_lbl = Label.new()
		
		# 1. Formato: "Common IronBoots x 4"
		name_lbl.text = "%s\nx%d" % [item_ref.name, count]
		
		# 2. Alineación
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# 3. Color según rareza
		var text_color = RARITY_COLORS.get(rarity_str, Color.WHITE)
		name_lbl.add_theme_color_override("font_color", text_color)
		
		# Opcional: Hacer la fuente un poco más pequeña si el texto es muy largo
		# name_lbl.add_theme_font_size_override("font_size", 14)
		
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
