extends CharacterBody2D

@onready var anim = $AnimatedSprite2D # Usaremos esto en el paso de animación
@onready var hitbox = $Hitbox # Referencia al área de ataque
@onready var hurtbox = $Hurtbox
var stats: HeroData
var target: CharacterBody2D # La unidad enemiga
var is_dead = false
var unit_name: String = "" # Para identificar si soy "BlackDragon" o "MaleViking"
var current_health=0
var attack_start_time: float = 0.0
var attack_attempting: bool = false
var damage_dealt: bool = false
@onready var main_collision = get_node("CollisionShape2D")

func _ready():
	add_to_group("heroGroup")
	$Hurtbox.add_to_group("hero_hurtbox")
	# Conectar la señal de cuando el arma toca algo
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	# Conectamos el cambio de frame
	anim.frame_changed.connect(_on_frame_changed)
	

func initialize(data: HeroData, _target: CharacterBody2D):
	stats = data.duplicate(true)
	target = _target
	unit_name = data.name
	current_health=data.health
	
	# Configurar equipos para evitar fuego amigo
	if is_in_group("heroGroup"):
		$Hurtbox.add_to_group("hero_hurtbox")
	else:
		$Hurtbox.add_to_group("enemy_hurtbox")
		
	if anim: anim.play("Walk")
		
func _physics_process(_delta):
	if is_dead: return
	# Valida si los ataques causan daño, sino, cambia de objetivo
	if attack_attempting:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - attack_start_time
		if elapsed >= 2.0:
			if not damage_dealt:
				print("No damage dealt in 2s, switching target")
				var new_target = get_random_enemy()
				if new_target:
					target = new_target
					try_attack(target) 
			attack_attempting = false

	if not is_instance_valid(target):
		target = get_closest_enemy()
	
	if not target:
		if anim.animation != "Idle": anim.play("Idle")
		return
	
	var distance = global_position.distance_to(target.global_position)

	if distance > stats.attack_range:
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * stats.speed
		move_and_slide()
		if anim.animation != "Walk": anim.play("Walk")
		if anim:
			if direction.x < 0:
				anim.flip_h = true
			elif direction.x > 0:
				anim.flip_h = false
	else:
		velocity = Vector2.ZERO
		var direction = global_position.direction_to(target.global_position)
		if anim:
			if direction.x < 0:
				anim.flip_h = true
				hitbox.scale.x = -1
			elif direction.x > 0:
				anim.flip_h = false
				hitbox.scale.x = 1
		if anim.animation != "Attack_1":
			try_attack(target)


func get_closest_enemy() -> CharacterBody2D:
	var shortest_distance = INF
	var closest: CharacterBody2D = null
	for enemy in get_tree().get_nodes_in_group("enemyGroup"):
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			closest = enemy as CharacterBody2D
	return closest

# Busca a un enemigo al azar
func get_random_enemy() -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemyGroup")
	var valid: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead and enemy != target:
			valid.append(enemy)
	if valid.size() == 0:
		return null
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return valid[rng.randi_range(0, valid.size() - 1)] as CharacterBody2D

func take_damage(amount: int) -> bool:
	if is_dead: 
		return false
	
	var damage = max(amount - stats.defense, 1)
	stats.health -= damage
	
	# Feedback visual
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if stats.health <= 0:
		await die()
		return true
	
	return damage > 0

	
func die() -> void:
	if is_dead: return
	is_dead = true
	if is_instance_valid(hitbox):
		if hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.disconnect(_on_hitbox_area_entered)
		hitbox.queue_free()

	if is_instance_valid(hurtbox):
		hurtbox.queue_free()

	main_collision.set_deferred("disabled", true)
	anim.play("Death")
	await anim.animation_finished
	queue_free()
	
func _on_hitbox_area_entered(area):
	var is_hero = is_in_group("heroGroup")
	var is_enemy_hurtbox = area.is_in_group("enemy_hurtbox")
	var is_hero_hurtbox = area.is_in_group("hero_hurtbox")
	
	if (is_hero and is_enemy_hurtbox) or (not is_hero and is_hero_hurtbox):
		var victim = area.get_parent()
		if victim.has_method("take_damage"):
			var did_damage = await victim.take_damage(stats.damage)
			if did_damage:
				damage_dealt = true
				attack_attempting = false


func _on_frame_changed():
	if is_dead or not is_instance_valid(hitbox): return
	
	var shape = hitbox.get_node_or_null("CollisionShape2D")
	var polygon = hitbox.get_node_or_null("CollisionPolygon2D")
	if shape: shape.disabled = true
	if polygon: polygon.disabled = true
	
	if anim.animation == "Attack_1" and anim.frame >= 2 and anim.frame <= 3:
		if shape: shape.disabled = false
		if polygon: polygon.disabled = false
		
		# Revisa si los hitbox y hurtbox conectan
		for area in hitbox.get_overlapping_areas():
			if area.is_in_group("enemy_hurtbox"):
				var victim = area.get_parent()
				if victim and victim.has_method("take_damage"):
					var did_damage = await victim.take_damage(stats.damage)
					if did_damage:
						# Recibimos respuesta de daño, mantener objetivo actual
						attack_attempting = false
					else:
						# Si no hay daño, cambia el target
						print("Cambiando objetivo")
						var new_target = get_random_enemy()
						if new_target:
							target = new_target
							try_attack(target)

# Intenta atacar
func try_attack(target_enemy: CharacterBody2D):
	target = target_enemy
	attack_start_time = Time.get_ticks_msec() / 1000.0
	attack_attempting = true
	damage_dealt = false  
	anim.play("Attack_1")


func apply_upgrade():
	# Aumentar stats actuales (ej. +20%)
	stats.health = int(stats.health * 1.2)
	current_health = int(current_health * 1.2) # Curar la diferencia o subir el tope
	stats.damage = int(stats.damage * 1.2)
	
	# Efecto visual (Crecer un poco y brillar amarillo)
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.2, 0.5).set_trans(Tween.TRANS_BOUNCE)
	modulate = Color(2, 2, 0) # Brillo Amarillo intenso
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1) # Volver a normal
	
	print(unit_name, " ha subido de nivel en pleno combate!")
