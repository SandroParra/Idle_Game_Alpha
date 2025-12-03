extends Area2D

var value: int = 10
var target_ui_position: Vector2

func initialize(start_pos: Vector2, ui_target: Vector2):
	global_position = start_pos
	target_ui_position = ui_target
	
	# Efecto visual: "Saltar" un poco antes de viajar a la UI
	var tween = create_tween()
	# 1. Escalar de 0 a 1 (Pop up)
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1,1), 0.3).set_trans(Tween.TRANS_BACK)
	
	# 2. Esperar un momento
	tween.tween_interval(0.2)
	
	# 3. Viajar hacia el contador de Experiencia
	tween.tween_property(self, "global_position", target_ui_position, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# 4. Al llegar, destruir y sumar experiencia
	tween.tween_callback(_on_reached_target)

func _on_reached_target():
	# Llamamos al GameManager para sumar la XP
	var game_manager = get_node("/root/Game")
	if game_manager and game_manager.has_method("add_experience"):
		game_manager.add_experience(value)
	else:
		print("Error: XPDrop no pudo encontrar el nodo 'Game' o la función 'add_experience'")
	queue_free()
