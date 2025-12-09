extends Area2D

var value: int = 10
var target_ui_position: Vector2
var xp_amount: int = 0

func initialize(start_pos: Vector2, ui_target: Vector2, xp: int):
	global_position = start_pos
	z_index = 100 # Para que las orbes de exp se dibujen encima de todo (torres, suelo, héroes)
	target_ui_position = ui_target
	xp_amount = xp
	
	# Efecto visual: "Saltar" un poco antes de viajar a la UI
	var tween = create_tween()
	
	# FASE 1: "POP" (Salto aleatorio)
	# La orbe salta un poco hacia los lados para que no se amontonen si mueren muchos enemigos
	var random_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
	var pop_pos = start_pos + random_offset
	
	# 1. Escalar de 0 a 1 (Pop up)
	scale = Vector2.ZERO
	tween.set_parallel(true) # Ejecutar movimiento y escala a la vez
	tween.tween_property(self, "global_position", pop_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_ELASTIC)
	tween.set_parallel(false) # Terminar paralelo
	
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
		game_manager.add_experience(xp_amount)
	else:
		print("Error: XPDrop no pudo encontrar el nodo 'Game' o la función 'add_experience'")
	queue_free()
