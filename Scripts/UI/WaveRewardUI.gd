extends CanvasLayer

signal continue_pressed

@export var grid: Container 
@onready var continue_btn = $Panel/VBoxContainer/ContinueButton # Revisa que esta ruta también sea correcta

var loot_list: Array = []

func _ready():
	if grid == null:
		print("ERROR FATAL: No has asignado el nodo ItemGrid en el Inspector de WaveRewardUI")
		return
		
	continue_btn.pressed.connect(_on_continue_pressed)
	get_tree().paused = true
	
	# Si set_loot_data se llamó antes del _ready, mostramos los datos ahora
	if not loot_list.is_empty():
		display_loot()

func set_loot_data(items: Array):
	loot_list = items.duplicate()
	
	#Solo pintamos si el nodo ya está listo ---
	if is_node_ready() and grid:
		display_loot()

func display_loot():
	# Limpieza
	for child in grid.get_children():
		child.queue_free()
	
	if loot_list.is_empty():
		var label = Label.new()
		label.text = "Sin recompensas..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(label)
		return

	for item_data in loot_list:
		var slot = VBoxContainer.new()
		var icon_rect = TextureRect.new()
		if "icon" in item_data and item_data.icon:
			icon_rect.texture = item_data.icon
		
		icon_rect.custom_minimum_size = Vector2(64, 64)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var name_lbl = Label.new()
		if "item_name" in item_data:
			name_lbl.text = item_data.item_name
		else:
			name_lbl.text = "Item"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		slot.add_child(icon_rect)
		slot.add_child(name_lbl)
		grid.add_child(slot)

func _on_continue_pressed():
	get_tree().paused = false
	continue_pressed.emit()
	queue_free()
