extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim = $AnimatedSprite2D # Usaremos esto en el paso de animación
@onready var hitbox = $Hitbox # Referencia al área de ataque
@onready var hurtbox = $Hurtbox

@export var stats: EnemyData

var target: CharacterBody2D = null
var is_dead = false

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
	if is_dead: return # No moverse si está muerto
	
	var enemy = get_closest_enemy()
	if enemy == null:
		animated_sprite.play("Idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var enemy_distance = global_position.distance_to(enemy.global_position)
	var direction = global_position.direction_to(enemy.global_position)
# Detenerse para atacar un poco antes (ej. 50px) para no solaparse
	if enemy_distance <= 50: 
		velocity = Vector2.ZERO
		attack(enemy)
	else:
		velocity = direction * stats.speed
		animated_sprite.play("Walk")
		if animated_sprite:
			if direction.x < 0:
				animated_sprite.flip_h = false # Mirar izquierda
			elif direction.x > 0:
				animated_sprite.flip_h = true # Mirar derecha
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

func take_damage(amount: int) -> void:
	if is_dead: return

	var damage = max(amount - stats.defense, 1)
	stats.health -= damage
	print(stats.name, " recibio daño. Vida: ", stats.health)
	
	if stats.health <= 0:
		die()
		return # Salimos para que no se ejecute el parpadeo si ya murió
		
	# Feedback visual (parpadeo rojo solo si sigue vivo)
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		modulate = Color(1, 1, 1)
	

func die() -> void:
	if is_dead: return
	
	is_dead = true
	print("Enemy defeated!")
	if hitbox: hitbox.queue_free()
	if hurtbox: hurtbox.queue_free()
	$CollisionShape2D.set_deferred("disabled", true)
	anim.play("Death")
	await anim.animation_finished
	queue_free()
	
func _on_death_animation_finished():
	queue_free()

func _on_hitbox_area_entered(area):
	# Validar Fuego Amigo:
	# Si soy Héroe, no ataco 'hero_hurtbox', solo 'enemy_hurtbox'
	var is_enemy = is_in_group("enemyGroup")
	var is_enemy_hurtbox = area.is_in_group("enemy_hurtbox")
	var is_hero_hurtbox = area.is_in_group("hero_hurtbox")
	
	# Si soy heroe y toco enemigo O si soy enemigo y toco heroe
	if (is_enemy and is_hero_hurtbox) or (not is_enemy and is_enemy_hurtbox):
		# El area es el Hurtbox, el padre es la Unidad (Unit.gd)
		var victim = area.get_parent()
		if victim and victim.has_method("take_damage"):
			print("¡Golpe exitoso a ", victim.name, "!")
			victim.take_damage(stats.damage)

func _on_frame_changed():
	if is_dead or not is_instance_valid(hitbox): return
			
	var shape = hitbox.get_node_or_null("CollisionShape2D")
	var polygon = hitbox.get_node_or_null("CollisionPolygon2D")
	if shape: shape.disabled = true
	if polygon: polygon.disabled = true
	
	if anim.animation == "Attack_1":
		# El golpe visual ocurre en el frame 2 y 3
		
		if (anim.frame >= 2 and anim.frame <= 3):
			if shape: shape.disabled = false
			if polygon: polygon.disabled = false
