# res://Scripts/CardUI.gd
extends TextureRect

# Señales para avisar al juego que estamos tocando la carta
signal drag_started(card_data)
signal drag_ended(card_data)

@export var card_data: HeroData # Arrastraremos BlackDragon.tres aquí

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Click detectado - Iniciando arrastre") # Debug
				drag_started.emit(card_data)
				# Click presionado: Empezar arrastre
				#drag_started.emit(card_data)
			else:
				print("Click soltado - Terminando arrastre") # Debug
				# Click soltado: Terminar arrastre
				drag_ended.emit(card_data)

func setup(data: HeroData):
	print("Configurando carta...") # Debug
	card_data = data
	
	# Actualizamos la imagen inmediatamente
	if card_data and card_data.icon:
		texture = card_data.icon # Si usas TextureRect directo
		print("Icono asignado: ", card_data.icon.resource_path)
		# Si se tiene un nodo hijo para el icono, seria: $Icon.texture = card_data.icon
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		custom_minimum_size = Vector2(0, 0) # AJUSTA ESTO al tamaño que quieras
		# De tener labels de costo:
		# $CostLabel.text = str(card_data.elixir_cost)
	else:
		print("ERROR: setup() recibió datos vacíos o sin icono")
		# Poner un color de fondo para ver si la carta existe aunque no tenga imagen
		modulate = Color(1, 0, 0) # Se pondrá roja si falla
