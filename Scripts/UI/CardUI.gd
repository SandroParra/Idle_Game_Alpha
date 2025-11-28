extends Control

# Señales que escuchará el GameManager
signal card_selected(card_data)
signal card_deselected

@export var card_data: CardData
@onready var icon: TextureRect = $Icon
@onready var cost_lbl: Label = $Cost

func _ready():
	if card_data:
		icon.texture = card_data.icon
		cost_lbl.text = str(card_data.cost)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			card_selected.emit(card_data)
		else:
			# Opcional: Si quieres lógica al soltar el clic
			pass
