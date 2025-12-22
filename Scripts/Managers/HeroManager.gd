extends Control

@onready var back_btn = $BackButton

# Lista de IDs de tus héroes en orden
var hero_ids = ["BlackDragon", "MaleViking", "MaleKnight"]
var current_hero_index = 0
var active_slot_name = "" # Variable para recordar qué slot clickeamos
var item_pending_equip: ItemData = null

# --- REFERENCIAS UI PRINCIPAL ---
@export var hero_name_label: Label
@export var facet_buttons: Array[Button]
# Array de TextureButtons que forman el "Paper Doll"
@export var inventory_slots_ui: Array[Control]

# --- REFERENCIAS DE NAVEGACIÓN ---
@export_group("Navigation Buttons")
@export var btn_prev: Button
@export var btn_next: Button

# --- REFERENCIAS MODAL ---
@export_group("Modal References")
@export var modal_panel: Control        # El panel completo (ModalSelector)
@export var modal_grid: Container       # Donde van los botones de items (GridContainer)
@export var modal_title: Label          # Título "Selecciona Casco..."
@export var modal_close_btn: Button

# --- REFERENCIAS PARA COMPARACIÓN (Arrastra los nodos aquí en el Inspector) ---
@export_group("Comparison UI")
@export var comparison_modal: Control
@export var comp_equip_btn: Button
@export var comp_cancel_btn: Button

# Lado Izquierdo (Actual)
@export var left_icon: TextureRect
@export var left_name: Label
@export var left_stats: RichTextLabel 
@export var left_rarity: Label

# Lado Derecho (Nuevo)
@export var right_icon: TextureRect
@export var right_name: Label
@export var right_stats: RichTextLabel
@export var right_rarity: Label

# Se debe cargar los Recursos (Resources) saber nombres/iconos
var hero_resources = {
	"BlackDragon": preload("res://Resources/Data/Heroes/BlackDragon.tres"),
	"MaleViking": preload("res://Resources/Data/Heroes/MaleViking.tres"),
	"MaleKnight": preload("res://Resources/Data/Heroes/MaleKnight.tres")
}

func _ready():
# 1. Conectar señales de slots del inventario
	var slot_names = PlayerData.SLOTS
	for i in range(inventory_slots_ui.size()):
		if i < slot_names.size():
			var slot_control = inventory_slots_ui[i]
			if not slot_control.pressed.is_connected(_on_slot_clicked):
				slot_control.pressed.connect(_on_slot_clicked.bind(slot_names[i]))
	
	# 2. Conectar Navegación (Prev/Next) Manualmente
	if btn_prev and not btn_prev.pressed.is_connected(_on_prev_hero_pressed):
		btn_prev.pressed.connect(_on_prev_hero_pressed)
	if btn_next and not btn_next.pressed.is_connected(_on_next_hero_pressed):
		btn_next.pressed.connect(_on_next_hero_pressed)

	# 3. CONECTAR BOTÓN CERRAR (NUEVO)
	if modal_close_btn:
		# Al presionar, simplemente ocultamos el panel
		modal_close_btn.pressed.connect(func(): modal_panel.hide())

	# Ocultar modal al inicio
	if modal_panel:
		modal_panel.hide()
	
	update_ui()
			
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	else:
		print("Error: No se encontró el nodo BackButton en la escena")
	
	# Conexiones nuevas
	if comp_equip_btn: comp_equip_btn.pressed.connect(_on_confirm_equip)
	if comp_cancel_btn: comp_cancel_btn.pressed.connect(_on_cancel_comparison)
	
	# Asegurar que el modal esté oculto al inicio
	if comparison_modal: comparison_modal.hide()
	
func update_ui():
	var current_id = hero_ids[current_hero_index]
	var current_data = PlayerData.heroes_data[current_id]
	var current_res = hero_resources[current_id]
	
	# 1. Actualizar Nombre
	hero_name_label.text = current_res.name
	
	# 2. Cargar Inventario Específico de este héroe
	# Iteramos tus slots visuales y les decimos qué item mostrar
	var inv_data = current_data["inventory"]
	var slot_names = PlayerData.SLOTS
	
	for i in range(inventory_slots_ui.size()):
		if i < slot_names.size():
			var slot_name = slot_names[i]
			var item = inv_data.get(slot_name)
			
			# Si por error hay un dropData (la caja) en vez del ItemData, lo extraemos.
			if item is DropData:
				if item.item_data:
					item = item.item_data
				else:
					item = null # Caja vacía, mejor no mostrar nada
			# -----------------------------------
			
			# Usamos tu función personalizada o lógica estándar si es TextureButton
			if inventory_slots_ui[i].has_method("display_item"):
				inventory_slots_ui[i].display_item(item)
			elif inventory_slots_ui[i] is TextureButton:
				
				# --- AJUSTE DE ESCALA (NUEVO) ---
				inventory_slots_ui[i].ignore_texture_size = true # Fuerza a respetar el tamaño del botón
				inventory_slots_ui[i].stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED # Mantiene la proporción sin deformar
				# --------------------------------
				
				if item and "icon" in item:
					inventory_slots_ui[i].texture_normal = item.icon
					inventory_slots_ui[i].tooltip_text = item.name
				else:
					inventory_slots_ui[i].texture_normal = null # O tu imagen de slot vacío
					inventory_slots_ui[i].tooltip_text = "Vacío"

	# 3. Cargar Facetas Específicas
	# Si no encuentra la clave, asume que es la faceta 0
	var active_facet_idx = current_data.get("selected_facet_index", 0)
	
	for i in range(facet_buttons.size()):
		if i < current_res.available_facets.size():
			var f_data = current_res.available_facets[i]
			
			if f_data == null:
				facet_buttons[i].hide() #ya no crashea si una faceta es nula
				continue # Saltamos al siguiente botón del bucle
			
			facet_buttons[i].text = f_data.name
			facet_buttons[i].show()
			
			# Colores
			if i == active_facet_idx:
				facet_buttons[i].modulate = Color.GREEN
			else:
				facet_buttons[i].modulate = Color.WHITE
				
			# Reconectar señales para que envíen el ID actual
			if facet_buttons[i].pressed.is_connected(_on_facet_selected):
				facet_buttons[i].pressed.disconnect(_on_facet_selected)
			facet_buttons[i].pressed.connect(_on_facet_selected.bind(i, current_id))
		else:
			facet_buttons[i].hide() # Ocultar botones sobrantes si el héroe tiene menos facetas

# Función para cambiar de héroe con las flechas
# --- CAMBIO DE HÉROE (CON AUTO-CLOSE) ---
func _on_next_hero_pressed():
	if modal_panel: modal_panel.hide() # <--- NUEVO: Cierra el modal al cambiar
	current_hero_index = (current_hero_index + 1) % hero_ids.size()
	update_ui()

func _on_prev_hero_pressed():
	if modal_panel: modal_panel.hide() # <--- NUEVO: Cierra el modal al cambiar
	current_hero_index = (current_hero_index - 1 + hero_ids.size()) % hero_ids.size()
	update_ui()

func _on_facet_selected(facet_idx: int, hero_id: String):
	PlayerData.heroes_data[hero_id]["selected_facet_index"] = facet_idx
	update_ui()

# --- LÓGICA DEL MODAL DE INVENTARIO ---
# 1. Al hacer click en un slot del Paper Doll
func _on_slot_clicked(slot_name: String):
	active_slot_name = slot_name
	modal_title.text = "<< " + slot_name.capitalize() + " Inventory >>"
	
	# Limpiar grid
	for child in modal_grid.get_children():
		child.queue_free()
	
	# Buscar items en mochila global
	var items_found = false
	for item in PlayerData.global_inventory:
		# 1. Verificación de Seguridad Básica
		if item == null: continue
		# Nota: Como ahora es Array[ItemData], Godot sabe que 'item' tiene .slot_type
		# Pero por seguridad en caso de migración, podemos chequear:
		if not "slot_type" in item: continue

		# 2. COMPARAMOS DIRECTAMENTE
		# (Opcional) Debug para ver qué está pasando si algo falla
		# print("Revisando: ", item.name, " | Tipo: ", item.slot_type)
		
		if item.slot_type.to_lower() == slot_name.to_lower():
			create_modal_button(item)
			items_found = true
			
	if not items_found:
		print("RESULTADO: No se encontraron coincidencias para ", slot_name)
		var lbl = Label.new()
		lbl.text = "No items here."
		modal_grid.add_child(lbl)
		
	# Botón Desequipar
	var current_inv = PlayerData.heroes_data[hero_ids[current_hero_index]]["inventory"]
	if current_inv.get(slot_name) != null:
		var btn_unequip = Button.new()
		btn_unequip.text = "Unequip"
		btn_unequip.modulate = Color(1, 0.3, 0.3)
		btn_unequip.pressed.connect(_on_unequip_item)
		modal_grid.add_child(btn_unequip)
	
	modal_panel.show()

# Helper para crear botones en el grid
func create_modal_button(item_res):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	
	if item_res.icon:
		btn.icon = item_res.icon
		btn.expand_icon = true # ¡CRUCIAL! Permite que el icono se encoja
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	btn.tooltip_text = item_res.name
	
	# Conectar pasando el item específico
	btn.pressed.connect(_on_item_selected_from_modal.bind(item_res))
	modal_grid.add_child(btn)

# 2. Al seleccionar un item del modal
func _on_item_selected_from_modal(item: ItemData):
	# En lugar de equipar directamente, guardamos la referencia y mostramos comparación
	item_pending_equip = item
	show_comparison_modal(item)

func show_comparison_modal(new_item: ItemData):
	var current_hero_id = hero_ids[current_hero_index]
	
	# 1. Obtener el item actualmente equipado en ese slot
	var current_inv = PlayerData.heroes_data[current_hero_id]["inventory"]
	# active_slot_name es la variable que guardamos cuando abriste el inventario (ej: "helmet")
	var equipped_item = current_inv.get(active_slot_name)
	
	# 2. Llenar UI Izquierda (Equipado)
	if equipped_item != null:
		left_name.text = equipped_item.name
		left_icon.texture = equipped_item.icon
		left_rarity.text = equipped_item.rarity
		left_stats.text = generate_stat_text(equipped_item) # Texto simple
		
		# Color de rareza (Opcional)
		left_rarity.modulate = get_rarity_color(equipped_item.rarity)
	else:
		left_name.text = "Vacio"
		left_icon.texture = null # O una textura de 'Empty Slot'
		left_rarity.text = ""
		left_stats.text = "No hay item equipado"

	# 3. Llenar UI Derecha (Nuevo) y COMPARAR
	if new_item != null:
		right_name.text = new_item.name
		right_icon.texture = new_item.icon
		right_rarity.text = new_item.rarity
		right_rarity.modulate = get_rarity_color(new_item.rarity)
		
		# Aquí generamos el texto comparativo
		right_stats.text = generate_comparison_text(equipped_item, new_item)
		
	# 4. Mostrar el panel
	comparison_modal.show()
	# Ocultamos el grid de inventario para que se vea limpio (opcional)
	modal_panel.hide()

func _on_confirm_equip():
	if item_pending_equip == null: return
	
	var current_id = hero_ids[current_hero_index]
	
	# Lógica original de equipamiento
	PlayerData.equip_item_from_bag(current_id, active_slot_name, item_pending_equip)
	
	# Actualizar UI y cerrar modales
	update_ui()
	PlayerData.save_game()
	
	comparison_modal.hide()
	modal_panel.hide() # Cerrar también el selector
	item_pending_equip = null

func _on_cancel_comparison():
	comparison_modal.hide()
	modal_panel.show() # Volver a mostrar la lista de items por si quiere elegir otro
	item_pending_equip = null

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
	
# 3. Al desequipar
func _on_unequip_item():
	var current_id = hero_ids[current_hero_index]
	PlayerData.unequip_item(current_id, active_slot_name)
	modal_panel.hide()
	update_ui()
	PlayerData.save_game()

func _on_back_pressed():
	print("Saliendo al Menú Principal...")
	
	# GUARDADO DE SEGURIDAD:
	PlayerData.save_game()
	print("Guardado con éxito...")
	# CAMBIAR DE ESCENA
	# Ajusta esta ruta si tu menú está en otra carpeta
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu.tscn")
