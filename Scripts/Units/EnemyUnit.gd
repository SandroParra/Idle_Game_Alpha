extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim = $AnimatedSprite2D # Usaremos esto en el paso de animación
@onready var hitbox = $Hitbox # Referencia al área de ataque
@onready var hurtbox = $Hurtbox
@onready var main_collision = get_node("CollisionShape2D")

@export var possible_drops: Array[dropData] = []
@export var stats: EnemyData

var target: CharacterBody2D = null
var is_dead = false
var xp_drop_scene = preload("res://Scenes/Levels/Drop/XPDrop.tscn")

func _ready():
	add_to_group("enemyGroup")
	if hurtbox:
		hurtbox.add_to_group("enemy_hurtbox")
	
	if stats == null:
		push_warning("Enemy has no stats assigned")
		return
	else:
		stats = stats.duplicate()
		
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	anim.frame_changed.connect(_on_frame_changed)
	# animation_finished ya no es necesario para hacer daño, solo para cleanup

func _physics_process(_delta: float) -> void:
	if is_dead: return
	
	var enemy = get_closest_enemy()
	target = enemy
	
	if enemy == null:
		animated_sprite.play("Idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var target_pos = get_target_hurtbox_position()
	var direction = global_position.direction_to(target_pos)
	var enemy_distance = global_position.distance_to(target_pos)
	
	if enemy_distance > stats.attack_range:
		# Too far → keep chasing
		velocity = direction * stats.speed
		animated_sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		attack(enemy)
	
	if direction.x < 0:
		animated_sprite.flip_h = false
		hitbox.position.x = -abs(hitbox.position.x)
	elif direction.x > 0:
		animated_sprite.flip_h = true
		hitbox.position.x = abs(hitbox.position.x)
	move_and_slide()

	
	
func get_closest_enemy() -> CharacterBody2D:
	var shortest_distance = INF
	var closest: CharacterBody2D = null
	for enemy in get_tree().get_nodes_in_group("heroGroup"):
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			closest = enemy as CharacterBody2D
	return closest

func attack(target_enemy: CharacterBody2D):
	target = target_enemy
	animated_sprite.play("Attack_1")

func _on_animation_finished():
	pass

func take_damage(amount: int) -> bool:
	if is_dead: 
		return false

	var damage = max(amount - stats.defense, 1)
	stats.health -= damage
	
	if stats.health <= 0:
		die()
		return true   # damage applied, enemy died
	
	# Feedback visual
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		modulate = Color(1, 1, 1)
	
	return damage > 0   # true if damage was applied

func die() -> void:
	if is_dead: return
	is_dead = true

	call_deferred("spawn_xp")
	call_deferred("roll_loot")  # NEW

	if hitbox: hitbox.queue_free()
	if hurtbox: hurtbox.queue_free()
	main_collision.set_deferred("disabled", true)
	anim.play("Death")
	await anim.animation_finished
	queue_free()

func roll_loot():
	if possible_drops.is_empty():	return
		
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root

	for drop_data in possible_drops:
		# 1. Chequeamos que el recurso no sea nulo
		if drop_data == null: continue
		# 2. DETECTOR DE IMPOSTORES (Uso estricto de tipos)
		# Verificamos si este recurso es realmente de la clase 'dropData'
		if not (drop_data is dropData):
			print("---------------------------------------------------")
			print("¡ALERTA! Se encontró un recurso inválido en la lista de drops.")
			print("El archivo culpable es: ", drop_data.resource_path)
			print("Tipo detectado: ", drop_data.get_class())
			print("SOLUCIÓN: Ve al Inspector del enemigo y quita este archivo de 'Possible Drops'.")
			print("---------------------------------------------------")
			continue # Saltamos este item para que el juego no se rompa
		
		# 3. Si llegamos aquí, es un dropData legítimo y seguro
		if drop_data.item_scene and randf() <= drop_data.drop_chance:
			var item: Node = drop_data.item_scene.instantiate()
			item.add_to_group("dropped_items") 
			parent.add_child(item)

			var item2d := item as Node2D
			if item2d:
				item2d.global_position = global_position

				var tween := item2d.create_tween()
				var start_pos := item2d.global_position
				var jump_height := -20 
				var duration := 0.2     

				tween.tween_property(
					item2d, "global_position",
					start_pos + Vector2(0, jump_height),
					duration
				).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

				tween.tween_property(
					item2d, "global_position",
					start_pos,
					duration
				).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				
			var game = get_node("/root/Game") 
			if game and game.has_method("register_drop"):
				game.register_drop(drop_data)
	
func _on_death_animation_finished():
	queue_free()

func _on_hitbox_area_entered(area):
	var is_enemy = is_in_group("enemyGroup")
	var is_enemy_hurtbox = area.is_in_group("enemy_hurtbox")
	var is_hero_hurtbox = area.is_in_group("hero_hurtbox")
	
	if (is_enemy and is_hero_hurtbox) or (not is_enemy and is_enemy_hurtbox):
		var victim = area.get_parent()
		if victim and victim.has_method("take_damage"):
			velocity = Vector2.ZERO   
			attack(victim)            


func _on_frame_changed():
	if is_dead or not is_instance_valid(hitbox): return
			
	var shape = hitbox.get_node_or_null("CollisionShape2D")
	var polygon = hitbox.get_node_or_null("CollisionPolygon2D")
	if shape: shape.disabled = true
	if polygon: polygon.disabled = true
	
	if anim.animation == "Attack_1":
		if anim.frame >= 2 and anim.frame <= 3:
			if shape: shape.disabled = false
			if polygon: polygon.disabled = false
			
			for area in hitbox.get_overlapping_areas():
				if area.is_in_group("hero_hurtbox"):
					var victim = area.get_parent()
					if victim and victim.has_method("take_damage"):
						victim.take_damage(stats.damage)

func get_xp_reward() -> int:
	return stats.xp_gain

#Agregada instancia de xp dinamico dependiendo de nuevo campo "xp_gain" en las stats del enemigo
func spawn_xp():
	var drop = xp_drop_scene.instantiate()
	drop.add_to_group("dropped_items")
	# Lo añadimos a la raíz del juego para que no se mueva con el enemigo muerto
	get_tree().root.add_child(drop) 
	
	# Obtenemos la posición destino del GameManager
	var target_pos = Vector2(50, 50) # Default
	# Como GameManager es un nodo en la escena, accedemos vía ruta absoluta o Singleton
	# Asumiendo que GameManager es el nodo raiz "/root/Game"
	var game = get_node("/root/Game") 
	if game and game.has_method("get_xp_icon_position"):
		target_pos = game.get_xp_icon_position()
		
	var xp_reward = stats.xp_gain
	drop.initialize(global_position, target_pos, xp_reward)
		
func get_target_hurtbox_position() -> Vector2:
	if target and target.has_node("Hurtbox"):
		return target.get_node("Hurtbox").get_node("CollisionShape2D").global_position
	return target.global_position
