extends Node

const RARITY_COLORS = {
	"Common": Color("#ffffff"),
	"Uncommon": Color("#44bd32"),
	"Rare": Color("#4a90e2"),
	"Epic": Color("#9013fe"),
	"Legendary": Color("#f5a623")
}

# Devuelve el color basado en la rareza (útil para otros scripts)
func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

# Función Maestra de Estilo Visual
func update_slot_visual_style(slot_node: Control, item_data: Dictionary):
	# 1. Obtener referencias a los nodos hijos esperados
	var icon_node = slot_node.get_node_or_null("Icon")
	var border_node = slot_node.get_node_or_null("Border")
	var level_label = slot_node.get_node_or_null("LevelLabel")
	# Opcional: Si el slot tiene un Label para el nombre (ej. en el panel de acción)
	var name_label = slot_node.get_node_or_null("NameLabel") 

	# 2. CASO: SLOT VACÍO
	if item_data == null or item_data.is_empty():
		if icon_node: icon_node.texture = null
		if border_node: border_node.hide()
		if level_label: level_label.text = ""
		if name_label: name_label.text = ""
		slot_node.tooltip_text = "" # Limpiar tooltip
		return

	# 3. Datos Básicos
	var rarity = item_data.get("rarity", "Common")
	var rarity_color = get_rarity_color(rarity)
	var item_name = item_data.get("name", "Unknown Item")
	
	# 4. Actualizar Icono
	if icon_node and item_data.has("icon"):
		var icon_val = item_data["icon"]
		if icon_val is String and icon_val != "":
			icon_node.texture = load(icon_val)
		elif icon_val is Texture2D:
			icon_node.texture = icon_val

	# 5. Actualizar Borde (Color según rareza)
	if border_node:
		border_node.show()
		border_node.self_modulate = rarity_color

	# 6. Actualizar Nivel (+X en la esquina)
	if level_label:
		var level = item_data.get("upgrade_level", 0)
		if level > 0:
			level_label.text = "+%d" % level
			level_label.show()
			# Lógica visual: Amarillo si es alto nivel, Blanco si es bajo
			level_label.modulate = Color.YELLOW if level >= 5 else Color.WHITE
		else:
			level_label.text = ""
			level_label.hide()

	# 7. Actualizar Tooltip (Standard)
	# Nota: Los tooltips nativos de Godot no soportan colores en el texto fácilmente sin un tema personalizado.
	# Aquí configuramos el texto formateado.
	slot_node.tooltip_text = "%s\n(%s)" % [item_name, rarity]
	
	# 8. (Opcional) Si hay un NameLabel explícito (ej. Action Panel), lo coloreamos
	if name_label:
		name_label.text = item_name
		name_label.add_theme_color_override("font_color", rarity_color)
