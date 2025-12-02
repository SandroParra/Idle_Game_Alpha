# res://Scripts/CardUI.gd
extends TextureRect

# Señales para avisar al juego que estamos tocando la carta
signal drag_started(card_data)
signal drag_ended(card_data)

@export var card_data: HeroData # Arrastraremos BlackDragon.tres aquí

func _ready():
	# Cargar visuales automáticamente
	if card_data:
		texture = card_data.icon
		# Si tienes un Label para el costo:
		$Label.text = str(card_data.name)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Click detectado - Iniciando arrastre") # Debug
				drag_started.emit(card_data)
				# Click presionado: Empezar arrastre
				drag_started.emit(card_data)
			else:
				print("Click soltado - Terminando arrastre") # Debug
				# Click soltado: Terminar arrastre
				drag_ended.emit(card_data)
