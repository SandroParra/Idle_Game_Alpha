extends Panel

signal deck_confirmed(selected_deck: Array[HeroData])

@export var all_available_cards: Array[HeroData] # Arrastra aquí TODOS tus .tres
@export var max_selection: int = 3

var current_selection: Array[HeroData] = []
@onready var grid = $GridContainer
@onready var start_btn = $StartButton

func _ready():
	start_btn.disabled = true
	start_btn.pressed.connect(_on_start_pressed)
	
	# Generar botones visuales para cada carta disponible
	for card_data in all_available_cards:
		
		if card_data == null:
			print("Advertencia: Se encontró una ranura vacía en all_available_cards")
			continue
			
		var btn = TextureButton.new()
		
		# Configuración visual básica
		btn.texture_normal = card_data.icon
		btn.custom_minimum_size = Vector2(100, 140) # Tamaño de carta
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.ignore_texture_size = true
		
		# Guardamos los datos en el botón para usarlos luego
		btn.set_meta("data", card_data)
		
		# Conectar señal de click
		btn.pressed.connect(_on_card_clicked.bind(btn))
		
		grid.add_child(btn)

func _on_card_clicked(btn: TextureButton):
	var data = btn.get_meta("data")
	
	if data in current_selection:
		# DESELECCIONAR
		current_selection.erase(data)
		btn.modulate = Color(1, 1, 1) # Color normal
	else:
		# SELECCIONAR (Solo si no hemos llegado al límite)
		if current_selection.size() < max_selection:
			current_selection.append(data)
			btn.modulate = Color(0, 1, 0) # Verde para indicar seleccionado
		else:
			print("¡Ya elegiste el máximo de cartas!")
	
	# Activar botón de start solo si tenemos cartas
	start_btn.disabled = current_selection.is_empty()
	
	# Opcional: Actualizar texto del botón
	start_btn.text = "LISTO (%d/%d)" % [current_selection.size(), max_selection]

func _on_start_pressed():
	# Emitimos la lista de cartas elegidas y nos ocultamos
	deck_confirmed.emit(current_selection)
	queue_free() # Destruimos el selector
