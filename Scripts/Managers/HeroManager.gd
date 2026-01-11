extends Control

@onready var back_btn = $BackButton

# Lista de IDs de tus héroes en orden
var hero_ids = ["BlackDragon", "MaleViking", "MaleKnight"]
var current_hero_index = 0
var active_slot_filter = "" 
var item_pending_equip: ItemData = null

# --- REFERENCIAS UI PRINCIPAL ---
@export var hero_name_label: Label
@export var facet_buttons: Array[Button]
@export var inventory_slots_ui: Array[Control] # Paper Doll Slots

# --- REFERENCIAS UI RETRATO ---
@export_group("Hero Portrait")
@export var hero_portrait: TextureRect

# --- REFERENCIAS DE NAVEGACIÓN ---
@export_group("Navigation Buttons")
@export var btn_prev: Button
@export var btn_next: Button

# --- REFERENCIAS INVENTARIO ---
@export_group("Inventory Panel")
@export var inv_panel: Control          
@export var inv_grid: Container         
@export var inv_title: Label            
@export var btn_clear_filter: Button    
@export var btn_unequip_fixed: Button   

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

# --- REFERENCIAS A STATS ---
@export_group("Hero Stats Labels")
@export var lbl_health: Label
@export var lbl_phys_atk: Label
@export var lbl_magic_atk: Label
@export var lbl_phys_def: Label
@export var lbl_magic_def: Label
@export var lbl_crit_rate: Label
@export var lbl_crit_dmg: Label
@export var lbl_def_pen: Label

# --- COLORES DE RAREZA (Igual que en Forge) ---
const RARITY_COLORS = {
	"Common": Color("#9d9d9d"),   # Gris
	"Uncommon": Color("#44bd32"), # Verde
	"Rare": Color("#00a8ff"),     # Azul
	"Epic": Color("#8c7ae6"),     # Morado
	"Legendary": Color("#f1c40f") # Dorado
}

# Recursos
var hero_resources = {
	"BlackDragon": preload("res://Resources/Data/Heroes/BlackDragon.tres"),
	"MaleViking": preload("res://Resources/Data/Heroes/MaleViking.tres"),
	"MaleKnight": preload("res://Resources/Data/Heroes/MaleKnight.tres")
}

func _ready():
	# 1. Conexiones Paper Doll
	var slot_names = PlayerData.SLOTS
	for i in range(inventory_slots_ui.size()):
		if i < slot_names.size():
			var slot_control = inventory_slots_ui[i]
			if not slot_control.pressed.is_connected(_on_slot_clicked):
				slot_control.pressed.connect(_on_slot_clicked.bind(slot_names[i]))
	
	# 2. Navegación
	if btn_prev:
		if not btn_prev.pressed.is_connected(_on_prev_hero_pressed):
			btn_prev.pressed.connect(_on_prev_hero_pressed)
	if btn_next:
		if not btn_next.pressed.is_connected(_on_next_hero_pressed):
			btn_next.pressed.connect(_on_next_hero_pressed)

	# 3. Inventario
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
	
	if inv_panel: inv_panel.show()
	
	update_ui()
	refresh_inventory_grid("") 

func update_ui():
	var current_id = hero_ids[current_hero_index]
	var current_data = PlayerData.heroes_data[current_id]
	var current_res = hero_resources[current_id]
	
	# 1. Nombre
	if hero_name_label: hero_name_label.text = current_res.name
	
	# 2. Retrato
	if hero_portrait:
		var path = "res://Assets/UI/%s/%s.png" % [current_id, current_id]
		if ResourceLoader.exists(path):
			hero_portrait.texture = load(path)
		else:
			hero_portrait.texture = null
	
	# 3. Paper Doll (Actualizado con Borde y Nivel)
	var inv_data = current_data["inventory"]
	var slot_names = PlayerData.SLOTS
	
	for i in range(inventory_slots_ui.size()):
		if i < slot_names.size():
			var slot_name = slot_names[i]
			var item = inv_data.get(slot_name)
			
			if item is DropData and item.item_data: item = item.item_data
			elif item is DropData: item = null
			
			var ui_slot = inventory_slots_ui[i]
			
			# Configuración base de textura
			if ui_slot is TextureButton or ui_slot is TextureRect:
				if ui_slot is TextureButton:
					ui_slot.ignore_texture_size = true
					ui_slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				else:
					ui_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					ui_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

				if item and "icon" in item:
					if ui_slot is TextureButton: ui_slot.texture_normal = item.icon
					else: ui_slot.texture = item.icon
					ui_slot.tooltip_text = "%s\nLvl +%d (%s)" % [item.name, item.level, item.rarity]
				else:
					if ui_slot is TextureButton: ui_slot.texture_normal = null 
					else: ui_slot.texture = null
					ui_slot.tooltip_text = slot_name
			
			# --- NUEVO: Aplicar Borde y Texto de Nivel ---
			update_slot_visual_style(ui_slot, item)
	
	# 4. Facetas
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
			
	# 5. Stats
	update_hero_stats_labels(current_id, current_res)

# --- FUNCIÓN HELPER VISUAL (PAPER DOLL & INVENTORY) ---
func update_slot_visual_style(control_node: Control, item: ItemData):
	# Nombres de los nodos hijos que crearemos dinámicamente
	var border_name = "DynamicBorder"
	var lvl_lbl_name = "DynamicLvlLbl"
	
	# 1. Buscar o Crear Borde (Panel)
	# NOTA: Ponemos el mouse_filter en IGNORE para que el clic pase al botón de abajo
	var border = control_node.get_node_or_null(border_name)
	if not border:
		border = Panel.new()
		border.name = border_name
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		control_node.add_child(border)
	
	# 2. Buscar o Crear Label de Nivel
	var lbl = control_node.get_node_or_null(lvl_lbl_name)
	if not lbl:
		lbl = Label.new()
		lbl.name = lvl_lbl_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		
		# Configuración visual
		lbl.add_theme_font_size_override("font_size", 12)
		# Un borde negro fuerte al texto ayuda a que se lea sobre cualquier icono
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 4)
		
		# --- CORRECCIÓN DE POSICIÓN ---
		# 1. Anclar a la esquina superior derecha
		lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		
		# 2. CRÍTICO: Decirle que crezca hacia la IZQUIERDA (hacia adentro)
		lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		# Y hacia abajo
		lbl.grow_vertical = Control.GROW_DIRECTION_END
		
		# 3. Resetear los offsets para que se pegue exactamente a la esquina
		lbl.offset_left = 0
		lbl.offset_top = 0
		lbl.offset_right = 0
		lbl.offset_bottom = 0
		
		# 4. (Opcional) Añadir un pequeño margen interno (padding) para que no toque el borde exacto
		# Usamos margin_right porque está alineado a la derecha
		lbl.add_theme_constant_override("margin_right", 4)
		lbl.add_theme_constant_override("margin_top", 2)
		
		control_node.add_child(lbl)

	# 3. Aplicar Datos si hay item, o esconder si no
	if item:
		border.show()
		lbl.show()
		
		# Color del borde según rareza
		var style = StyleBoxFlat.new()
		style.draw_center = false # Solo borde, sin fondo
		style.set_border_width_all(2)
		style.border_color = RARITY_COLORS.get(item.rarity, Color.WHITE)
		style.set_corner_radius_all(4)
		border.add_theme_stylebox_override("panel", style)
		
		# Texto de nivel
		if item.level > 0:
			lbl.text = "+%d" % item.level
			# Color del texto según rareza (opcional, o blanco)
			# lbl.add_theme_color_override("font_color", RARITY_COLORS.get(item.rarity, Color.WHITE))
			lbl.add_theme_color_override("font_color", Color.WHITE) # Blanco suele leerse mejor con borde negro
		else:
			lbl.text = "" # Si es nivel 0, no mostramos nada
	else:
		border.hide()
		lbl.hide()

func _on_next_hero_pressed():
	comparison_modal.hide()
	item_pending_equip = null
	current_hero_index = (current_hero_index + 1) % hero_ids.size()
	update_ui()
	if active_slot_filter != "":
		update_unequip_button_state()

func _on_prev_hero_pressed():
	comparison_modal.hide()
	item_pending_equip = null
	current_hero_index = (current_hero_index - 1 + hero_ids.size()) % hero_ids.size()
	update_ui()
	if active_slot_filter != "":
		update_unequip_button_state()

func _on_facet_selected(facet_idx: int, hero_id: String):
	PlayerData.heroes_data[hero_id]["selected_facet_index"] = facet_idx
	update_ui()
	
func update_hero_stats_labels(hero_id: String, base_res: Resource):
	var stats = PlayerData.calculate_hero_stats(hero_id, base_res)
	if lbl_health: lbl_health.text = str(int(ceil(stats["health"])))
	if lbl_phys_atk: lbl_phys_atk.text = str(int(ceil(stats["physical_attack"])))
	if lbl_magic_atk: lbl_magic_atk.text = str(int(ceil(stats["magical_attack"])))
	if lbl_phys_def: lbl_phys_def.text = str(int(ceil(stats["physical_defense"])))
	if lbl_magic_def: lbl_magic_def.text = str(int(ceil(stats["magical_defense"])))
	if lbl_crit_rate: lbl_crit_rate.text = "%.1f%%" % (stats["critical_rate"] * 100.0)
	if lbl_def_pen: 
		var val = stats["defense_penetration"] * 100.0
		lbl_def_pen.text = str(int(ceil(val))) + "%"
	if lbl_crit_dmg: 
		lbl_crit_dmg.text = str(int(ceil(stats["critical_damage"]))) + "%"

# ==============================================================================
# LÓGICA DE INVENTARIO
# ==============================================================================

func _on_slot_clicked(slot_name: String):
	refresh_inventory_grid(slot_name)

func _on_clear_filter_pressed():
	refresh_inventory_grid("")

func refresh_inventory_grid(filter_slot: String):
	active_slot_filter = filter_slot
	
	if filter_slot == "":
		inv_title.text = "Full Inventory"
		if btn_clear_filter: btn_clear_filter.hide()
		if btn_unequip_fixed: btn_unequip_fixed.hide()
	else:
		inv_title.text = "<< " + filter_slot.capitalize() + " >>"
		if btn_clear_filter: btn_clear_filter.show()
		update_unequip_button_state()

	for child in inv_grid.get_children():
		child.queue_free()
	
	var items_found = false
	var display_list = PlayerData.global_inventory
	
	for item in display_list:
		if item == null: continue
		if not "slot_type" in item: continue
		
		if filter_slot == "" or item.slot_type.to_lower() == filter_slot.to_lower():
			create_inventory_button(item)
			items_found = true
			
	if not items_found:
		var lbl = Label.new()
		lbl.text = "Empty..."
		inv_grid.add_child(lbl)

func update_unequip_button_state():
	if not btn_unequip_fixed: return
	if active_slot_filter == "":
		btn_unequip_fixed.hide()
		return
	var current_inv = PlayerData.heroes_data[hero_ids[current_hero_index]]["inventory"]
	if current_inv.get(active_slot_filter) != null:
		btn_unequip_fixed.text = "Unequip " + active_slot_filter.capitalize()
		btn_unequip_fixed.show()
	else:
		btn_unequip_fixed.hide()

func create_inventory_button(item_res):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	
	if item_res.icon:
		btn.icon = item_res.icon
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# --- CAMBIO: Tooltip ahora muestra el nivel ---
	btn.tooltip_text = "%s +%d\n(%s)" % [item_res.name, item_res.level, item_res.rarity]
	
	# --- CAMBIO: Usamos el mismo helper para decorar el botón del inventario ---
	# Nota: Como Button ya tiene estilos, usar el helper que añade un Panel hijo
	# funciona bien para superponer el borde sin romper el estilo del botón base.
	update_slot_visual_style(btn, item_res)
	
	btn.pressed.connect(_on_item_selected_from_grid.bind(item_res))
	inv_grid.add_child(btn)

func _on_item_selected_from_grid(item: ItemData):
	item_pending_equip = item
	var target_slot = item.slot_type
	if active_slot_filter != "":
		target_slot = active_slot_filter
	show_comparison_modal(item, target_slot)

# ==============================================================================
# COMPARACIÓN
# ==============================================================================

func show_comparison_modal(new_item: ItemData, slot_name: String):
	var slot_to_compare = slot_name
	var current_hero_id = hero_ids[current_hero_index]
	var current_inv = PlayerData.heroes_data[current_hero_id]["inventory"]
	var equipped_item = current_inv.get(slot_to_compare)
	
	# Llenar lado Izquierdo (Equipado)
	if equipped_item:
		# --- CAMBIO: Mostrar nivel en el nombre ---
		left_name.text = "%s +%d" % [equipped_item.name, equipped_item.level]
		left_icon.texture = equipped_item.icon
		left_rarity.text = equipped_item.rarity
		left_stats.text = generate_stat_text(equipped_item)
		
		var l_col = RARITY_COLORS.get(equipped_item.rarity, Color.WHITE)
		left_rarity.modulate = l_col
		left_name.modulate = l_col
	else:
		left_name.text = "Empty Slot"
		left_name.modulate = Color.WHITE
		left_icon.texture = null
		left_rarity.text = ""
		left_stats.text = "-"

	# Llenar lado Derecho (Nuevo)
	if new_item:
		# --- CAMBIO: Mostrar nivel en el nombre ---
		right_name.text = "%s +%d" % [new_item.name, new_item.level]
		right_icon.texture = new_item.icon
		right_rarity.text = new_item.rarity
		
		var r_col = RARITY_COLORS.get(new_item.rarity, Color.WHITE)
		right_rarity.modulate = r_col
		right_name.modulate = r_col
		
		right_stats.text = generate_comparison_text(equipped_item, new_item)
		
	comparison_modal.show()

# ... (El resto de funciones: _on_confirm_equip, _on_cancel_comparison, _on_unequip_item, _on_back_pressed y helpers de texto SE MANTIENEN IGUAL) ...
func _on_confirm_equip():
	if item_pending_equip == null: return
	var current_id = hero_ids[current_hero_index]
	var target_slot = active_slot_filter
	if target_slot == "": target_slot = item_pending_equip.slot_type
	PlayerData.equip_item_from_bag(current_id, target_slot, item_pending_equip)
	update_ui()
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
	PlayerData.unequip_item(current_id, active_slot_filter)
	update_ui()
	refresh_inventory_grid(active_slot_filter)
	comparison_modal.hide()
	if item_pending_equip: item_pending_equip = null
	PlayerData.save_game()

func generate_stat_text(item: ItemData) -> String:
	var text = ""
	# (Aquí va tu lógica de generate_stat_text original)
	# Para abreviar, pega aquí la misma función que ya tenías
	# Solo recuerda que calculate_hero_stats ya multiplica por nivel,
	# pero item.physical_attack aquí muestra el valor base.
	# Si quieres mostrar el valor POTENCIADO por nivel aquí, deberías multiplicar:
	var lvl_mult = 1.0 + (item.level * 0.10)
	
	if item.physical_attack > 0: text += "Phy ATK: %d\n" % int(item.physical_attack * lvl_mult)
	if item.magical_attack > 0: text += "Mag ATK: %d\n" % int(item.magical_attack * lvl_mult)
	if item.health > 0: text += "HP: %d\n" % int(item.health * lvl_mult)
	if item.physical_defense > 0: text += "Phy DEF: %d\n" % int(item.physical_defense * lvl_mult)
	if item.magical_defense > 0: text += "Mag DEF: %d\n" % int(item.magical_defense * lvl_mult)
	if item.critical_damage > 0: text += "Crit Dmg: %d%%\n" % item.critical_damage

	if item.attack_mod > 0: text += "%% ATK: %.1f%%\n" % item.attack_mod
	if item.critical_rate > 0: text += "%% Crit: %.1f%%\n" % item.critical_rate
	if item.health_mod > 0: text += "%% HP: %.1f%%\n" % item.health_mod
	if item.defense_mod > 0: text += "%% DEF: %.1f%%\n" % item.defense_mod
	if item.defense_penetration > 0: text += "DEF Pen: %.1f%%\n" % item.defense_penetration
	return text

func generate_comparison_text(old_item: ItemData, new_item: ItemData) -> String:
	var text = ""
	var attributes = {
		"physical_attack": "Phy ATK", "magical_attack": "Mag ATK",
		"health": "HP", "physical_defense": "Phy DEF", "magical_defense": "Mag DEF",
		"attack_mod": "% ATK", "critical_rate": "% Crit", "critical_damage": "Crit Dmg",
		"health_mod": "% HP", "defense_mod": "% DEF", "defense_penetration": "DEF Pen"
	}
	var percentage_keys = ["attack_mod", "critical_rate", "critical_damage", "health_mod", "defense_mod", "defense_penetration"]
	
	# Multiplicadores de nivel
	var old_mult = 1.0
	if old_item: old_mult = 1.0 + (old_item.level * 0.10)
	
	var new_mult = 1.0
	if new_item: new_mult = 1.0 + (new_item.level * 0.10)
	
	for attr in attributes:
		var raw_new = new_item.get(attr) if new_item else 0
		var raw_old = old_item.get(attr) if old_item else 0
		
		# Aplicar multiplicador si NO es porcentaje
		var val_new = raw_new
		var val_old = raw_old
		
		if not attr in percentage_keys:
			val_new = raw_new * new_mult
			val_old = raw_old * old_mult
		
		if val_new == 0 and val_old == 0: continue
			
		var label = attributes[attr]
		var diff = val_new - val_old
		
		var suffix = "%" if attr in percentage_keys else ""
		var is_float = (typeof(val_new) == TYPE_FLOAT) or (not attr in percentage_keys) # Stats escalados son float ahora
		
		# Formateo
		var val_str = ""
		if attr in percentage_keys:
			# Porcentajes tal cual (float pequeño o int grande)
			if raw_new is float: val_str = "%.1f%s" % [raw_new, suffix]
			else: val_str = "%d%s" % [raw_new, suffix]
		else:
			# Stats planos escalados (mostrar como int)
			val_str = "%d" % int(val_new)
			
		var diff_str = ""
		if diff == 0:
			diff_str = "[color=#888888](=)[/color]"
		else:
			var diff_abs = abs(diff)
			var diff_num = ""
			if attr in percentage_keys:
				diff_num = "%.1f%s" % [diff_abs, suffix]
			else:
				diff_num = "%d" % int(diff_abs)
				
			if diff > 0: diff_str = "[color=#00ff00](+%s)[/color]" % diff_num
			else: diff_str = "[color=#ff0000](-%s)[/color]" % diff_num
		
		text += "%s: %s %s\n" % [label, val_str, diff_str]
			
	if text == "": text = "Sin atributos especiales"
	return text

func _on_back_pressed():
	PlayerData.save_game()
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu.tscn")
