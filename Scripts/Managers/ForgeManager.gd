extends Control

# ==============================================================================
# 1. CONFIGURACIÓN Y REFERENCIAS
# ==============================================================================

# Configuración de costos y probabilidades
@export var config: ForgeConfig 

# --- PANTALLAS (Paneles contenedores) ---
@export_group("Screens")
@export var main_menu_node: Control      # Panel con botones grandes
@export var upgrade_panel_node: Control  # Panel de Upgrade
@export var recycle_panel_node: Control  # Panel de Recycle

# --- NAVEGACIÓN ---
@export_group("Navigation Buttons")
@export var btn_goto_upgrade: Button     # En MainMenu
@export var btn_goto_recycle: Button     # En MainMenu
@export var btn_back_upgrade: Button     # En UpgradePanel
@export var btn_back_recycle: Button     # En RecyclePanel
@export var btn_back_to_game: Button     # Salir de la forja

# --- POPUPS ---
@export_group("Popups")
@export var confirm_dialog: ConfirmationDialog
@export var result_popup: Control
@export var result_label: Label

# --- UI RECICLAJE ---
@export_group("Recycle UI")
@export var btn_recycle_common: Button
@export var btn_recycle_uncommon: Button
@export var btn_recycle_rare: Button
@export var btn_recycle_epic: Button
@export var btn_recycle_legendary: Button

# --- UI UPGRADE (Inventario y Acción) ---
@export_group("Upgrade UI")
@export var inventory_grid: Container        # El GridContainer dentro del Scroll

# --- UI UPGRADE: COMPARACIÓN ---
@export_group("Upgrade UI - Comparison")
@export var comp_current_slot: Control    # Panel/Control vacio donde irá el icono actual
@export var comp_current_name: Label      # Label nombre actual
@export var comp_next_slot: Control       # Panel/Control vacio donde irá el icono siguiente
@export var comp_next_name: Label         # Label nombre siguiente
@export var comp_stats_container: Container # VBoxContainer donde se listarán los stats

# --- UI UPGRADE: ACCIONES ---
@export_group("Upgrade UI - Actions")
@export var action_info_lbl: Label           # "Cost: 2 Stones"
@export var success_chance_lbl: Label        # "Chance: 50%"
@export var action_btn: Button               # Botón "Upgrade"
@export var stone_selector: OptionButton     # Dropdown

# --- MATERIALES ---
@export_group("Material Counters")
@export var lbl_mat_common: Label
@export var lbl_mat_uncommon: Label
@export var lbl_mat_rare: Label
@export var lbl_mat_epic: Label
@export var lbl_mat_legendary: Label
@export var lbl_mat_bless: Label
@export var lbl_mat_soul: Label

# ==============================================================================
# 2. VARIABLES DE ESTADO
# ==============================================================================
var selected_item: ItemData = null
var current_mode = "UPGRADE"
var is_selected_item_equipped: bool = false
var target_recycle_rarity_idx: int = -1
var rarity_order = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

# ==============================================================================
# 3. CICLO DE VIDA
# ==============================================================================
func _ready():
	if not config: printerr("ALERTA: ForgeConfig no asignado.")
	
	setup_navigation_connections()
	setup_recycle_buttons()
	setup_popups()
	setup_upgrade_actions()
	
	# Asegurar que los slots de comparación usen nodos internos para UIManager
	_prepare_comparison_slot(comp_current_slot)
	_prepare_comparison_slot(comp_next_slot)

	show_main_menu()

func setup_navigation_connections():
	if btn_goto_upgrade: btn_goto_upgrade.pressed.connect(show_upgrade_panel)
	if btn_goto_recycle: btn_goto_recycle.pressed.connect(show_recycle_panel)
	if btn_back_upgrade: btn_back_upgrade.pressed.connect(show_main_menu)
	if btn_back_recycle: btn_back_recycle.pressed.connect(show_main_menu)
	if btn_back_to_game: btn_back_to_game.pressed.connect(_on_exit_forge_pressed)

func setup_recycle_buttons():
	if btn_recycle_common: btn_recycle_common.pressed.connect(_on_bulk_recycle_pressed.bind(0))
	if btn_recycle_uncommon: btn_recycle_uncommon.pressed.connect(_on_bulk_recycle_pressed.bind(1))
	if btn_recycle_rare: btn_recycle_rare.pressed.connect(_on_bulk_recycle_pressed.bind(2))
	if btn_recycle_epic: btn_recycle_epic.pressed.connect(_on_bulk_recycle_pressed.bind(3))
	if btn_recycle_legendary: btn_recycle_legendary.pressed.connect(_on_bulk_recycle_pressed.bind(4))

func setup_popups():
	if confirm_dialog: confirm_dialog.confirmed.connect(_execute_bulk_recycle)
	if result_popup:
		result_popup.hide()
		var close = result_popup.get_node_or_null("BtnCloseResult")
		if close: close.pressed.connect(func(): result_popup.hide())

func setup_upgrade_actions():
	if action_btn: action_btn.pressed.connect(_on_upgrade_action_pressed)
	if stone_selector: stone_selector.item_selected.connect(_on_stone_type_changed)

# Helper para crear la estructura visual dentro de los slots de comparación
func _prepare_comparison_slot(slot: Control):
	if not slot: return
	# Limpiar si ya tiene hijos
	for c in slot.get_children(): c.queue_free()
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 3; icon.offset_top = 3; icon.offset_right = -3; icon.offset_bottom = -3
	slot.add_child(icon)
	
	var border = Panel.new()
	border.name = "Border"
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0,0,0,0)
	style.set_border_width_all(3)
	style.border_color = Color.WHITE
	border.add_theme_stylebox_override("panel", style)
	slot.add_child(border)
	
	var lvl = Label.new()
	lvl.name = "LevelLabel"
	lvl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl.add_theme_font_size_override("font_size", 14)
	lvl.add_theme_constant_override("outline_size", 4)
	lvl.add_theme_color_override("font_outline_color", Color.BLACK)
	lvl.offset_left = -30
	slot.add_child(lvl)

# ==============================================================================
# 4. PANTALLAS
# ==============================================================================
func show_main_menu():
	if main_menu_node: main_menu_node.show()
	if upgrade_panel_node: upgrade_panel_node.hide()
	if recycle_panel_node: recycle_panel_node.hide()

func show_upgrade_panel():
	current_mode = "UPGRADE"
	if main_menu_node: main_menu_node.hide()
	if upgrade_panel_node: upgrade_panel_node.show()
	if recycle_panel_node: recycle_panel_node.hide()
	selected_item = null
	refresh_ui()

func show_recycle_panel():
	current_mode = "RECYCLE"
	if main_menu_node: main_menu_node.hide()
	if upgrade_panel_node: upgrade_panel_node.hide()
	if recycle_panel_node: recycle_panel_node.show()
	update_material_labels()

func _on_exit_forge_pressed():
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu.tscn")

# ==============================================================================
# 5. UI GENERATION (INVENTARIO)
# ==============================================================================
func refresh_ui():
	if current_mode != "UPGRADE": return
	update_material_labels()
	reset_action_panel()
	
	if not inventory_grid: return
	for child in inventory_grid.get_children(): child.queue_free()
	
	var all_items_info = []
	for item in PlayerData.global_inventory:
		if item: all_items_info.append({"item": item, "equipped": false})
	for h_id in PlayerData.heroes_data:
		var inv = PlayerData.heroes_data[h_id].get("inventory", {})
		for slot in inv:
			if inv[slot]:
				all_items_info.append({"item": inv[slot], "equipped": true, "hero_id": h_id, "slot": slot})
	
	for info in all_items_info:
		create_item_button(info)

func create_item_button(info):
	var item_ref = info["item"]
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.text = "" 
	
	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	#icon_rect.custom_minimum_size = Vector2(65, 65)
	icon_rect.offset_left = 3; icon_rect.offset_top = 3; icon_rect.offset_right = -3; icon_rect.offset_bottom = -3
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_rect)
	
	var border_panel = Panel.new()
	border_panel.name = "Border"
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(3)
	style.border_color = Color.WHITE
	border_panel.add_theme_stylebox_override("panel", style)
	btn.add_child(border_panel)
	
	var lvl_lbl = Label.new()
	lvl_lbl.name = "LevelLabel"
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lvl_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lvl_lbl.offset_left = -30; lvl_lbl.offset_top = 2; lvl_lbl.offset_right = -6
	lvl_lbl.add_theme_font_size_override("font_size", 16)
	lvl_lbl.add_theme_constant_override("outline_size", 4)
	lvl_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_child(lvl_lbl)
	
	if info["equipped"]:
		var eq_lbl = Label.new()
		eq_lbl.text = "Eq"
		eq_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		eq_lbl.offset_left = 4; eq_lbl.offset_bottom = -2
		eq_lbl.add_theme_font_size_override("font_size", 12)
		eq_lbl.add_theme_color_override("font_color", Color.GREEN)
		eq_lbl.add_theme_constant_override("outline_size", 3)
		eq_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_child(eq_lbl)
	
	var item_dict = _item_to_dict(item_ref)
	UIManager.update_slot_visual_style(btn, item_dict)
	
	btn.pressed.connect(_on_item_selected.bind(info))
	inventory_grid.add_child(btn)

func _on_item_selected(info: Dictionary):
	selected_item = info["item"]
	is_selected_item_equipped = info["equipped"]
	populate_stone_selector()
	update_action_panel()

# ==============================================================================
# 6. LOGICA UPGRADE Y COMPARACIÓN
# ==============================================================================
func populate_stone_selector():
	if not stone_selector or not selected_item: return
	stone_selector.clear()
	
	var item_rarity_val = config.get_rarity_value(selected_item.rarity)
	var rarities = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var has_options = false
	
	for i in range(rarities.size()):
		if i >= item_rarity_val:
			var r_name = rarities[i]
			var count = PlayerData.get_material_count(r_name)
			stone_selector.add_item("%s Stone (x%d)" % [r_name, count], i)
			stone_selector.set_item_metadata(stone_selector.item_count - 1, r_name)
			has_options = true
			
	if not has_options:
		stone_selector.add_item("No valid stones")
		stone_selector.disabled = true
	else:
		stone_selector.disabled = false
		stone_selector.selected = 0

func update_action_panel():
	if not selected_item: return

	# 1. GENERAR ITEM SIMULADO (SIGUIENTE NIVEL)
	var next_item_sim = _simulate_upgrade(selected_item)
	
	# 2. MOSTRAR COMPARACIÓN VISUAL (ICONOS)
	_update_comparison_visuals(selected_item, next_item_sim)
	
	# 3. MOSTRAR COMPARACIÓN DE STATS (LISTA)
	_update_stats_comparison_list(selected_item, next_item_sim)

	# 4. LÓGICA DE COSTOS
	if selected_item.level >= 20:
		action_info_lbl.text = "MAX LEVEL REACHED"
		success_chance_lbl.text = ""
		action_btn.disabled = true
		stone_selector.hide()
		return
	
	stone_selector.show()
	if stone_selector.disabled or stone_selector.item_count == 0:
		action_btn.disabled = true
		return

	var next_lvl = selected_item.level + 1
	var cost_data = config.get_stone_cost(next_lvl)
	var stones_needed = cost_data["stone_count"]
	var selected_stone = stone_selector.get_item_metadata(stone_selector.selected)
	var available_stones = PlayerData.get_material_count(selected_stone)
	
	var chance = calculate_success_chance(selected_item, selected_stone)
	success_chance_lbl.text = "Success Chance: %d%%" % int(chance * 100)
	
	if chance >= 0.7: success_chance_lbl.add_theme_color_override("font_color", Color.GREEN)
	elif chance >= 0.4: success_chance_lbl.add_theme_color_override("font_color", Color.YELLOW)
	else: success_chance_lbl.add_theme_color_override("font_color", Color.RED)

	var can_afford = available_stones >= stones_needed
	var txt = "Cost: %d %s Stone(s)" % [stones_needed, selected_stone]
	if not can_afford: txt += " [MISSING]"
	
	action_info_lbl.text = txt
	action_btn.text = "Upgrade (+%d)" % next_lvl
	action_btn.disabled = not can_afford

# --- HELPER: ACTUALIZAR VISUALES COMPARATIVOS ---
func _update_comparison_visuals(curr: ItemData, next: ItemData):
	# Lado Izquierdo (Actual)
	if comp_current_slot:
		UIManager.update_slot_visual_style(comp_current_slot, _item_to_dict(curr))
	if comp_current_name:
		comp_current_name.text = curr.name + " (+%d)" % curr.level
		comp_current_name.add_theme_color_override("font_color", UIManager.get_rarity_color(curr.rarity))

	# Lado Derecho (Siguiente)
	if comp_next_slot:
		UIManager.update_slot_visual_style(comp_next_slot, _item_to_dict(next))
	if comp_next_name:
		# Ahora next.name ya incluye "Tempered" o "Ascended" gracias a la simulación
		comp_next_name.text = next.name + " (+%d)" % next.level
		comp_next_name.add_theme_color_override("font_color", UIManager.get_rarity_color(next.rarity))
		
		# Opcional: Si el texto es muy largo, reducir fuente
		if comp_next_name.text.length() > 20:
			comp_next_name.add_theme_font_size_override("font_size", 12)
		else:
			comp_next_name.remove_theme_font_size_override("font_size")

# --- HELPER: GENERAR LISTA DE STATS ---
func _update_stats_comparison_list(curr: ItemData, next: ItemData):
	if not comp_stats_container: return
	
	# Limpiar lista anterior
	for child in comp_stats_container.get_children():
		child.queue_free()
		
	# Definir qué stats vamos a comparar (Nombres legibles vs Variables)
	var stats_map = {
		"Phys. Atk": "physical_attack",
		"Mag. Atk": "magical_attack",
		"Phys. Def": "physical_defense",
		"Mag. Def": "magical_defense",
		"Health": "health",
		"Crit Rate": "critical_rate",
		"Crit Dmg": "critical_damage",
		"% HP": "mod_hp"
	}
	
	for label in stats_map:
		var var_name = stats_map[label]
		var val_curr = curr.get(var_name)
		var val_next = next.get(var_name)
		
		# Solo mostramos stats que tengan valor (o que cambien)
		if val_curr == null: val_curr = 0
		if val_next == null: val_next = 0
		
		# Solo mostramos stats que tengan valor (o que cambien)
		if val_curr > 0 or val_next > 0:
			var diff = val_next - val_curr
			if diff == 0: continue 
			
			var row = HBoxContainer.new()
			
			# Nombre Stat
			var lbl_name = Label.new()
			lbl_name.text = label + ": "
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl_name)
			
			# Valores "10 -> 12"
			var lbl_vals = Label.new()
			# Formateo especial para porcentajes (Crit rate)
			if "rate" in var_name or "mod" in var_name: 
				lbl_vals.text = "%.1f%% -> %.1f%%" % [val_curr * 100, val_next * 100]
			else:
				lbl_vals.text = "%d -> %d" % [val_curr, val_next]
			row.add_child(lbl_vals)
			
			# Diferencia "(+2)"
			var lbl_diff = Label.new()
			if "rate" in var_name:
				lbl_diff.text = " (+%.1f%%)" % (diff * 100)
			else:
				lbl_diff.text = " (+%d)" % diff
			
			lbl_diff.add_theme_color_override("font_color", Color.GREEN)
			row.add_child(lbl_diff)
			
			comp_stats_container.add_child(row)

# --- HELPER: SIMULAR UPGRADE ---
func _simulate_upgrade(original: ItemData) -> ItemData:
	# 1. Crear un duplicado exacto
	var simulated = original.duplicate()
	
	# 2. Forzar la subida de nivel usando la lógica interna del Item
	#    Esto ejecutará prefijos, bonos aleatorios, stats nuevos, etc.
	simulated.apply_level_up()
	
	return simulated

func _on_upgrade_action_pressed():
	if not selected_item: return
	do_upgrade_logic()

func do_upgrade_logic():
	var next_lvl = selected_item.level + 1
	var cost_data = config.get_stone_cost(next_lvl)
	var stones_needed = cost_data["stone_count"]
	var selected_stone = stone_selector.get_item_metadata(stone_selector.selected)
	
	PlayerData.consume_material(selected_stone, stones_needed)
	
	var chance = calculate_success_chance(selected_item, selected_stone)
	
	if randf() <= chance:
		# Llamamos a la función inteligente del item
		selected_item.apply_level_up()
		print("Upgrade Success! New Level: ", selected_item.level)
	else:
		print("Upgrade Failed")
	
	PlayerData.save_game()
	populate_stone_selector()
	update_action_panel()
	refresh_ui()

func calculate_success_chance(item: ItemData, stone_type: String) -> float:
	var idx = min(item.level, config.base_success_chance.size() - 1)
	var base = config.base_success_chance[idx]
	var item_val = config.get_rarity_value(item.rarity)
	var stone_val = config.get_rarity_value(stone_type)
	var diff = max(0, stone_val - item_val)
	var bonus = diff * config.rarity_bonus_per_tier
	return clamp(base + bonus, 0.0, 1.0)

# ==============================================================================
# 7. LOGICA BULK RECYCLE
# ==============================================================================
func _on_bulk_recycle_pressed(max_rarity_index: int):
	target_recycle_rarity_idx = max_rarity_index
	var rarity_name = rarity_order[max_rarity_index]
	confirm_dialog.title = "Bulk Recycle"
	confirm_dialog.dialog_text = "Recycle all %s and lower items?\nEquipped/Upgraded items are safe." % rarity_name.to_upper()
	confirm_dialog.popup_centered()

func _execute_bulk_recycle():
	if target_recycle_rarity_idx == -1: return
	var items_to_remove: Array[ItemData] = []
	var total_materials: Dictionary = {}
	
	for item in PlayerData.global_inventory:
		if item == null: continue
		if item.level > 0: continue
		if _get_rarity_index(item.rarity) <= target_recycle_rarity_idx:
			items_to_remove.append(item)
			_calculate_recycle_yield(item, total_materials)
	
	if items_to_remove.is_empty():
		show_result_popup("No recyclable items found.")
		return
		
	for item in items_to_remove: PlayerData.global_inventory.erase(item)
	for mat in total_materials: PlayerData.add_material(mat, total_materials[mat])
	
	PlayerData.save_game()
	update_material_labels()
	
	var msg = "Recycle Complete!\nObtained:\n"
	for mat in total_materials: msg += "- %s x%d\n" % [mat, total_materials[mat]]
	show_result_popup(msg)

func _calculate_recycle_yield(item: ItemData, totals: Dictionary):
	if not config: return
	var drops = config.recycle_table.get(item.rarity, {})
	for stone in drops:
		var data = drops[stone]
		if randf() <= data[0]:
			var qty = randi_range(data[1], data[2])
			if qty > 0:
				if not totals.has(stone): totals[stone] = 0
				totals[stone] += qty

func show_result_popup(text: String):
	if result_popup and result_label:
		result_label.text = text
		result_popup.show()
		result_popup.move_to_front()

# ==============================================================================
# 8. HELPERS
# ==============================================================================
func _item_to_dict(item: ItemData) -> Dictionary:
	if not item: return {}
	return {
		"name": item.name,
		"icon": item.icon.resource_path if item.icon else "",
		"rarity": item.rarity,
		"upgrade_level": item.level
	}

func reset_action_panel():
	if comp_current_slot: UIManager.update_slot_visual_style(comp_current_slot, {})
	if comp_next_slot: UIManager.update_slot_visual_style(comp_next_slot, {})
	if comp_current_name: comp_current_name.text = ""
	if comp_next_name: comp_next_name.text = ""
	if comp_stats_container: for c in comp_stats_container.get_children(): c.queue_free()
	
	if action_info_lbl: action_info_lbl.text = ""
	if success_chance_lbl: success_chance_lbl.text = ""
	if stone_selector: stone_selector.hide()
	if action_btn: action_btn.disabled = true

func update_material_labels():
	if lbl_mat_common: lbl_mat_common.text = str(PlayerData.get_material_count("Common"))
	if lbl_mat_uncommon: lbl_mat_uncommon.text = str(PlayerData.get_material_count("Uncommon"))
	if lbl_mat_rare: lbl_mat_rare.text = str(PlayerData.get_material_count("Rare"))
	if lbl_mat_epic: lbl_mat_epic.text = str(PlayerData.get_material_count("Epic"))
	if lbl_mat_legendary: lbl_mat_legendary.text = str(PlayerData.get_material_count("Legendary"))

func _get_rarity_index(r_name: String) -> int:
	return rarity_order.find(r_name)

func _on_stone_type_changed(_idx):
	update_action_panel()
