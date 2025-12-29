extends Control

@onready var back_btn = $BackButton

# Lista de IDs de tus héroes en orden
var hero_ids = ["BlackDragon", "MaleViking", "MaleKnight"]
var current_hero_index = 0
var active_slot_filter = "" # Variable para saber qué filtro está activo ("" = todos)
var item_pending_equip: ItemData = null

# --- REFERENCIAS UI PRINCIPAL ---
@export var hero_name_label: Label
@export var facet_buttons: Array[Button]
@export var inventory_slots_ui: Array[Control] # Paper Doll

# --- REFERENCIAS DE NAVEGACIÓN ---
@export_group("Navigation Buttons")
@export var btn_prev: Button
@export var btn_next: Button

# --- REFERENCIAS INVENTARIO (Antes Modal) ---
@export_group("Inventory Panel")
@export var inv_panel: Control          # El panel lateral (Antes ModalSelector)
@export var inv_grid: Container         # GridContainer de items
@export var inv_title: Label            # Título del panel
@export var btn_clear_filter: Button    # NUEVO: Botón para "Ver Todo"
@export var btn_unequip_fixed: Button   # NUEVO: Botón fijo para desequipar (opcional)

# --- REFERENCIAS PARA COMPARACIÓN ---
@export_group("Comparison UI")
@export var comparison_modal: Control
@export var comp_equip_btn: Button
@export var comp_cancel_btn: Button
@export var left_icon: TextureRect
@export var left_name: Label
@export var left_stats: RichTextLabel 
@export var left_rarity: Label
@export var right_icon: TextureRect
@export var right_name: Label
@export var right_stats: RichTextLabel
@export var right_rarity: Label

# Recursos
var hero_resources = {
	"BlackDragon": preload("res://Resources/Data/Heroes/BlackDragon.tres"),
	"MaleViking": preload("res://Resources/Data/Heroes/MaleViking.tres"),
	"MaleKnight": preload("res://Resources/Data/Heroes/MaleKnight.tres")
}

func _ready():
	# 1. Conectar señales de slots del Paper Doll
	var slot_names = PlayerData.SLOTS
	for i in range(inventory_slots_ui.size()):
		if i < slot_names.size():
			var slot_control = inventory_slots_ui[i]
			if not slot_control.pressed.is_connected(_on_slot_clicked):
				slot_control.pressed.connect(_on_slot_clicked.bind(slot_names[i]))
	
	# 2. Navegación
	if btn_prev:
		# Solo conectamos si NO estaba conectado antes
		if not btn_prev.pressed.is_connected(_on_prev_hero_pressed):
			btn_prev.pressed.connect(_on_prev_hero_pressed)
			
	if btn_next:
		if not btn_next.pressed.is_connected(_on_next_hero_pressed):
			btn_next.pressed.connect(_on_next_hero_pressed)

	# 3. NUEVO: Conectar botones del panel de inventario
	if btn_clear_filter:
		if not btn_clear_filter.pressed.is_connected(_on_clear_filter_pressed):
			btn_clear_filter.pressed.connect(_on_clear_filter_pressed)
		btn_clear_filter.hide() 
		
	if btn_unequip_fixed:
		if not btn_unequip_fixed.pressed.is_connected(_on_unequip_item):
			btn_unequip_fixed.pressed.connect(_on_unequip_item)
		btn_unequip_fixed.hide()

	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	
	# 4. Comparación
	if comp_equip_btn: comp_equip_btn.pressed.connect(_on_confirm_equip)
	if comp_cancel_btn: comp_cancel_btn.pressed.connect(_on_cancel_comparison)
	if comparison_modal: comparison_modal.hide()
	
	# 5. INICIALIZACIÓN
	# Aseguramos que el panel de inventario esté visible siempre
	if inv_panel: inv_panel.show()
	
	update_ui()
	
	# CARGA INICIAL: Mostrar todo el inventario sin filtros
	refresh_inventory_grid("") 

func update_ui():
	var current_id = hero_ids[current_hero_index]
	var current_data = PlayerData.heroes_data[current_id]
	var current_res = hero_resources[current_id]
	
	# 1. Nombre
	if hero_name_label: hero_name_label.text = current_res.name
	
	# 2. Paper Doll (Lado Izquierdo)
	var inv_data = current_data["inventory"]
	var slot_names = PlayerData.SLOTS
	
	for i in range(inventory_slots_ui.size()):
		if i < slot_names.size():
			var slot_name = slot_names[i]
			var item = inv_data.get(slot_name)
			
			# Corrección por si viene un DropData
			if item is DropData and item.item_data: item = item.item_data
			elif item is DropData: item = null
			
			# Mostrar en UI
			var ui_slot = inventory_slots_ui[i]
			
			# Configuración visual para TextureButton
			if ui_slot is TextureButton:
				ui_slot.ignore_texture_size = true
				ui_slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				if item and "icon" in item:
					ui_slot.texture_normal = item.icon
					ui_slot.tooltip_text = item.name
				else:
					ui_slot.texture_normal = null # Imagen vacía
					ui_slot.tooltip_text = slot_name
	
	# 3. Facetas (Sin cambios)
	var active_facet_idx = current_data.get("selected_facet_index", 0)
	for i in range(facet_buttons.size()):
		if i < current_res.available_facets.size():
			var f_data = current_res.available_facets[i]
			if f_data == null: 
				facet_buttons[i].hide()
				continue
			
			facet_buttons[i].text = f_data.name
			facet_buttons[i].show()
			facet_buttons[i].modulate = Color.GREEN if i == active_facet_idx else Color.WHITE
			
			if facet_buttons[i].pressed.is_connected(_on_facet_selected):
				facet_buttons[i].pressed.disconnect(_on_facet_selected)
			facet_buttons[i].pressed.connect(_on_facet_selected.bind(i, current_id))
		else:
			facet_buttons[i].hide()

# --- NAVEGACIÓN HÉROES ---
func _on_next_hero_pressed():
	comparison_modal.hide()      # Cierra el modal de comparación
	item_pending_equip = null    # Olvida el item que estabas a punto de equipar
	current_hero_index = (current_hero_index + 1) % hero_ids.size()
	# Al cambiar de héroe, ¿quieres resetear el filtro o mantenerlo?
	# Opción A: Resetear filtro
	# _on_clear_filter_pressed()
	# Opción B: Mantener filtro y solo actualizar Paper Doll (Actual)
	update_ui()
	# Si hay un filtro activo, verificar si el botón Desequipar debe actualizarse
	if active_slot_filter != "":
		update_unequip_button_state()

func _on_prev_hero_pressed():
	comparison_modal.hide()      # Cierra el modal de comparación
	item_pending_equip = null    # Olvida el item que estabas a punto de equipar
	current_hero_index = (current_hero_index - 1 + hero_ids.size()) % hero_ids.size()
	update_ui()
	if active_slot_filter != "":
		update_unequip_button_state()

func _on_facet_selected(facet_idx: int, hero_id: String):
	PlayerData.heroes_data[hero_id]["selected_facet_index"] = facet_idx
	update_ui()

# ==============================================================================
# LÓGICA DE INVENTARIO (FILTRADO Y VISUALIZACIÓN)
# ==============================================================================

# 1. Al hacer click en un slot del Paper Doll (FILTRAR)
func _on_slot_clicked(slot_name: String):
	# Si ya estábamos filtrando este slot, no hacemos nada (o recargamos)
	# if active_slot_filter == slot_name: return 
	
	refresh_inventory_grid(slot_name)

# 2. Botón "Limpiar Filtro" / "Ver Todo"
func _on_clear_filter_pressed():
	refresh_inventory_grid("") # Cadena vacía = Sin filtro

# 3. Función Central de Carga de Items
func refresh_inventory_grid(filter_slot: String):
	active_slot_filter = filter_slot
	
	# A. Actualizar Títulos y Botones
	if filter_slot == "":
		inv_title.text = "Full Inventory"
		if btn_clear_filter: btn_clear_filter.hide()
		if btn_unequip_fixed: btn_unequip_fixed.hide()
	else:
		inv_title.text = "<< " + filter_slot.capitalize() + " >>"
		if btn_clear_filter: btn_clear_filter.show()
		update_unequip_button_state()

	# B. Limpiar Grid
	for child in inv_grid.get_children():
		child.queue_free()
	
	# C. Buscar items y llenar Grid
	var items_found = false
	var display_list = PlayerData.global_inventory
	
	for item in display_list:
		if item == null: continue
		if not "slot_type" in item: continue
		
		# LÓGICA DE FILTRO:
		# Si filter_slot es "", pasa todo. Si tiene texto, debe coincidir.
		if filter_slot == "" or item.slot_type.to_lower() == filter_slot.to_lower():
			create_inventory_button(item)
			items_found = true
			
	if not items_found:
		var lbl = Label.new()
		lbl.text = "Empty..."
		inv_grid.add_child(lbl)

# Helper para ver si mostramos el botón desequipar
func update_unequip_button_state():
	if not btn_unequip_fixed: return
	
	# Solo mostrar si hay filtro activo Y el héroe tiene algo puesto ahí
	if active_slot_filter == "":
		btn_unequip_fixed.hide()
		return
		
	var current_inv = PlayerData.heroes_data[hero_ids[current_hero_index]]["inventory"]
	if current_inv.get(active_slot_filter) != null:
		btn_unequip_fixed.text = "Unequip " + active_slot_filter.capitalize()
		btn_unequip_fixed.show()
	else:
		btn_unequip_fixed.hide()

# Helper para crear botones (Icono Item)
func create_inventory_button(item_res):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	
	if item_res.icon:
		btn.icon = item_res.icon
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	btn.tooltip_text = item_res.name + "\n(" + item_res.rarity + ")"
	
	# Al presionar un item del inventario, abrimos comparación
	btn.pressed.connect(_on_item_selected_from_grid.bind(item_res))
	inv_grid.add_child(btn)

# 4. Al seleccionar un item del Grid
func _on_item_selected_from_grid(item: ItemData):
	item_pending_equip = item
	
	# Si estamos viendo "Todos los items" (sin filtro), necesitamos saber
	# en qué slot va este item para comparar.
	var target_slot = item.slot_type
	if active_slot_filter != "":
		target_slot = active_slot_filter
	
	# Pasamos el slot destino explícitamente para saber con qué comparar
	show_comparison_modal(item, target_slot)

# ==============================================================================
# LOGICA DE COMPARACIÓN Y EQUIPADO
# ==============================================================================

func show_comparison_modal(new_item: ItemData, slot_name: String):
	var slot_to_compare = slot_name
	var current_hero_id = hero_ids[current_hero_index]
	var current_inv = PlayerData.heroes_data[current_hero_id]["inventory"]
	var equipped_item = current_inv.get(slot_to_compare)
	
# Llenar lado Izquierdo (Equipado)
	if equipped_item:
		left_name.text = equipped_item.name
		left_icon.texture = equipped_item.icon
		left_rarity.text = equipped_item.rarity
		left_stats.text = generate_stat_text(equipped_item)
		left_rarity.modulate = get_rarity_color(equipped_item.rarity)
	else:
		left_name.text = "Empty Slot"
		left_icon.texture = null
		left_rarity.text = ""
		left_stats.text = "-"

	# Llenar lado Derecho (Nuevo)
	if new_item:
		right_name.text = new_item.name
		right_icon.texture = new_item.icon
		right_rarity.text = new_item.rarity
		right_rarity.modulate = get_rarity_color(new_item.rarity)
		right_stats.text = generate_comparison_text(equipped_item, new_item)
		
	comparison_modal.show()

func _on_confirm_equip():
	if item_pending_equip == null: return
	
	var current_id = hero_ids[current_hero_index]
	# Usamos el slot type del item si active_slot_filter está vacio, o el filtro activo
	var target_slot = active_slot_filter
	if target_slot == "": target_slot = item_pending_equip.slot_type
	
	PlayerData.equip_item_from_bag(current_id, target_slot, item_pending_equip)
	
	update_ui()
	# Refrescamos el grid para quitar el item equipado (si tu lógica lo quita de la bolsa global)
	# O simplemente para actualizar estados visuales
	refresh_inventory_grid(active_slot_filter)
	
	PlayerData.save_game()
	comparison_modal.hide()
	item_pending_equip = null

func _on_cancel_comparison():
	comparison_modal.hide()
	item_pending_equip = null

func _on_unequip_item():
	if active_slot_filter == "": return
	
	var current_id = hero_ids[current_hero_index]
	
	# 1. Mover item del héroe a la bolsa global
	PlayerData.unequip_item(current_id, active_slot_filter)
	
	# 2. Actualizar el Paper Doll (lado izquierdo) para que se vea vacío
	update_ui()
	
	# 3. Refrescar la grilla para ver el item que acaba de caer ---
	# Esto vuelve a leer el inventario global y dibuja el botón del item
	refresh_inventory_grid(active_slot_filter)

	# update_unequip_button_state() <-- Ya no hace falta llamarlo manual, refresh_inventory_grid lo hace
	
	# 4. Cerrar comparación si estaba abierta (para evitar estados raros)
	comparison_modal.hide()
	if item_pending_equip: item_pending_equip = null
	
	PlayerData.save_game()

# --- HELPERS DE TEXTO ---
func generate_stat_text(item: ItemData) -> String:
	var text = ""
	
	# --- STATS ENTEROS (%d) ---
	if item.physical_attack > 0: text += "Physical ATK: %d\n" % item.physical_attack
	if item.magical_attack > 0: text += "Magical ATK: %d\n" % item.magical_attack
	if item.health > 0: text += "HP: %d\n" % item.health
	if item.physical_defense > 0: text += "Physical DEF: %d\n" % item.physical_defense
	if item.magical_defense > 0: text += "Magical DEF: %d\n" % item.magical_defense
	if item.critical_damage > 0: text += "Crit Dmg: %d%%\n" % item.critical_damage

	# --- STATS DECIMALES (%.1f) ---
	if item.attack_mod > 0: text += "%% ATK: %.1f%%\n" % item.attack_mod
	if item.critical_rate > 0: text += "%% Crit: %.1f%%\n" % item.critical_rate
	if item.health_mod > 0: text += "%% HP: %.1f%%\n" % item.health_mod
	if item.defense_mod > 0: text += "%% DEF: %.1f%%\n" % item.defense_mod
	if item.defense_penetration > 0: text += "DEF Pen: %.1f%%\n" % item.defense_penetration

	return text

func generate_comparison_text(old_item: ItemData, new_item: ItemData) -> String:
	var text = ""
	
	# Diccionario: "nombre_variable": "Nombre a Mostrar"
	var attributes = {
		"physical_attack": "Physical ATK",
		"magical_attack": "Magical ATK",
		"attack_mod": "% ATK",
		"critical_rate": "% Crit",
		"critical_damage": "Crit Dmg", # Es INT pero lleva %
		"health": "HP",
		"health_mod": "% HP",
		"physical_defense": "Physical DEF",
		"magical_defense": "Magical DEF",
		"defense_mod": "% DEF",
		"defense_penetration": "DEF Pen"		
	}
	
	# Lista de atributos que deben llevar el símbolo "%" al final
	var percentage_keys = [
		"attack_mod", 
		"critical_rate", 
		"critical_damage", 
		"health_mod", 
		"defense_mod", 
		"defense_penetration"
	]
	
	for attr in attributes:
		# Obtenemos valores de forma segura
		var new_val = new_item.get(attr) if new_item else 0
		var old_val = old_item.get(attr) if old_item else 0
		
		# Si ambos son 0, saltamos
		if new_val == 0 and old_val == 0:
			continue
			
		var label = attributes[attr]
		var diff = new_val - old_val
		
		# Determinar si lleva símbolo de porcentaje
		var suffix = ""
		if attr in percentage_keys:
			suffix = "%"
		
		# --- DETECCIÓN DE TIPO ---
		var sample_val = new_val if new_val != 0 else old_val
		var is_float = (typeof(sample_val) == TYPE_FLOAT)
		
		# 1. Formatear el VALOR NUEVO (Columna central)
		var val_str = ""
		if is_float:
			val_str = "%.1f%s" % [new_val, suffix] # Ej: "5.5%"
		else:
			val_str = "%d%s" % [new_val, suffix]   # Ej: "50%" (Crit Dmg) o "150" (HP)
			
		# 2. Formatear la DIFERENCIA (Columna derecha)
		var diff_str = ""
		
		if diff == 0:
			diff_str = "[color=#888888](=)[/color]"
		else:
			var diff_num_str = ""
			# Formateamos el número absoluto de la diferencia y le pegamos el sufijo también
			if is_float:
				diff_num_str = "%.1f%s" % [abs(diff), suffix] 
			else:
				diff_num_str = "%d%s" % [abs(diff), suffix]
			
			if diff > 0:
				# Verde con signo +
				diff_str = "[color=#00ff00](+%s)[/color]" % diff_num_str
			else:
				# Rojo con signo -
				diff_str = "[color=#ff0000](-%s)[/color]" % diff_num_str
		
		# Construir línea final
		text += "%s: %s %s\n" % [label, val_str, diff_str]
			
	if text == "":
		text = "Sin atributos especiales"
		
	return text

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Common": return Color.GRAY
		"Uncommon": return Color.GREEN
		"Rare": return Color.CYAN
		"Epic": return Color.PURPLE
		"Legendary": return Color.ORANGE
	return Color.WHITE

func _on_back_pressed():
	PlayerData.save_game()
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu.tscn")
