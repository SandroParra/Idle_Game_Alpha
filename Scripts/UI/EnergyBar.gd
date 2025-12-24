extends TextureProgressBar

@onready var label = $EnergyLabel # Si decidiste ponerle texto

func update_bar(current_energy: int, max_energy: int):
	# Actualizamos los máximos por si cambian durante el juego
	max_value = max_energy
	
	# Opción A: Cambio instantáneo
	# value = current_energy
	
	# Opción B: Animación suave (Recomendado)
	var tween = create_tween()
	tween.tween_property(self, "value", current_energy, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Actualizar texto si existe
	if label:
		label.text = str(current_energy) + " / " + str(max_energy)
