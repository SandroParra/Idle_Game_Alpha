extends Control

@onready var back_btn = $BackButton

# Lista de IDs de tus héroes en orden
var hero_ids = ["BlackDragon", "MaleViking", "MaleKnight"]
var current_hero_index = 0
var active_slot_name = "" # Variable para recordar qué slot clickeamos

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
			if item is dropData:
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
	for raw_item in PlayerData.global_inventory:
		# 1. NORMALIZACIÓN DE DATOS
		var real_item = raw_item
		
		# Si por error guardamos un DropData, extraemos el ItemData de adentro
		if raw_item is dropData: # Nota: asegura que la clase se llame dropData o DropData según tu script
			if raw_item.item_data:
				real_item = raw_item.item_data
			else:
				continue # Si la caja está vacía, saltamos
		
		# 2. Verificación de Seguridad
		if real_item == null or not "slot_type" in real_item:
			continue

		# 3. AHORA SÍ COMPARAMOS (Usando real_item)
		print("Revisando: ", real_item.name, " | Tipo: ", real_item.slot_type)
		
		if real_item.slot_type.to_lower() == slot_name.to_lower():
			create_modal_button(real_item)
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
func _on_item_selected_from_modal(item):
	var current_id = hero_ids[current_hero_index]
	
	# Llamamos al Singleton para hacer el intercambio lógico de datos
	PlayerData.equip_item_from_bag(current_id, active_slot_name, item)
	
	modal_panel.hide()
	update_ui() # Refrescamos para ver el nuevo item equipado
	PlayerData.save_game()
	
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
