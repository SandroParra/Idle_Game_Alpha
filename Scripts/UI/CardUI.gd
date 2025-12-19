# res://Scripts/CardUI.gd
extends TextureRect

# Señales para avisar al juego que estamos tocando la carta
signal drag_started(card_data)
signal drag_ended(card_data)

@export var card_data: HeroData # Arrastraremos BlackDragon.tres aquí
@onready var lvl_label = $LevelLabel # Referencia al label que creamos
@onready var lvl_btn = $BtnLevelUp

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
		update_level_display()
		# Buscamos el nodo Game para escuchar cuando suba el nivel
		var game = get_node("/root/Game")
		if game:
			# Conectamos la señal. Usamos safe connect para no duplicar errores
			if not game.hero_level_changed.is_connected(_on_hero_level_changed):
				game.hero_level_changed.connect(_on_hero_level_changed)

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

func _ready():
	# Conectar el botón
	lvl_btn.pressed.connect(_on_level_up_pressed)

	# Escuchar cambios de XP para saber si puedo pagar
	# (Esto requiere que tengas acceso al GameManager, lo ideal es usar Señales globales)
	# Por ahora al hacer click verificamos.

func _on_level_up_pressed():
	# Pedir al GameManager que mejore ESTA carta
	var game = get_node("/root/Game")
	game.upgrade_hero_type(card_data)
	# Actualizar texto del botón o visuales de la carta
	# ej. Ponerle un marco dorado

func update_level_display():
	# Pedimos al GameManager el nivel actual de ESTE héroe
	var game = get_node("/root/Game")
	if game:
		# Si el diccionario tiene mi nombre, obtengo el nivel, si no, es 1
		var current_lvl = game.hero_levels.get(card_data.name, 1)
		lvl_label.text = "Lvl " + str(current_lvl)

func _on_hero_level_changed(hero_name: String, new_level: int):
	# Solo actualizamos si el héroe que subió de nivel SOY YO
	if card_data and card_data.name == hero_name:
		lvl_label.text = "Lvl " + str(new_level)
		
		# Efecto visual opcional: Un parpadeo para llamar la atención
		var tween = create_tween()
		tween.tween_property(lvl_label, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(lvl_label, "scale", Vector2(1.0, 1.0), 0.2)
