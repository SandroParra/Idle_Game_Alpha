extends CharacterBody2D

@onready var anim = $AnimatedSprite2D # Usaremos esto en el paso de animación
@onready var hitbox = $Hitbox # Referencia al área de ataque
@onready var hurtbox = $Hurtbox
var stats: HeroData
var target: CharacterBody2D # La unidad enemiga
var is_dead = false
var unit_name: String = "" # Para identificar si soy "BlackDragon" o "MaleViking"
var current_health=0

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
	# Si el objetivo actual dejó de existir (se murió), buscamos uno nuevo
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
		# Mirar hacia donde va (Flip horizontal)
		if anim:
			if direction.x < 0:
				anim.flip_h = true # Mirar izquierda
			elif direction.x > 0:
				anim.flip_h = false # Mirar derecha
	else:
		velocity = Vector2.ZERO
		# Solo iniciamos el ataque si no estamos atacando ya
		if anim.animation != "Attack_1":
			anim.play("Attack_1")

func get_closest_enemy() -> CharacterBody2D:
	var shortest_distance = INF
	var closest: CharacterBody2D = null
	for enemy in get_tree().get_nodes_in_group("enemyGroup"):
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			closest = enemy as CharacterBody2D
	return closest

func take_damage(amount: int) -> void:
	if is_dead: return
	var damage = max(amount - stats.defense, 1)
	stats.health -= damage
	#print("Hero took ", damage, " and has ", stats.health, " health remaining")
	
	# Feedback visual (parpadeo rojo)
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if stats.health <= 0:
		#is_dead = true;
		die()
		return
	
func die() -> void:
	if is_dead: return
	is_dead = true
	#print("Hero defeated!")
		
	# Limpieza de colisiones
	if is_instance_valid(hitbox): hitbox.queue_free()
	if is_instance_valid(hurtbox): hurtbox.queue_free()
	$CollisionShape2D.set_deferred("disabled", true)
		
	anim.play("Death")
	await anim.animation_finished
	queue_free()

func _on_hitbox_area_entered(area):
	# Validar Fuego Amigo:
	# Si soy Héroe, no ataco 'hero_hurtbox', solo 'enemy_hurtbox'
	var is_hero = is_in_group("heroGroup")
	var is_enemy_hurtbox = area.is_in_group("enemy_hurtbox")
	var is_hero_hurtbox = area.is_in_group("hero_hurtbox")
	
	# Si soy heroe y toco enemigo O si soy enemigo y toco heroe
	if (is_hero and is_enemy_hurtbox) or (not is_hero and is_hero_hurtbox):
		# El area es el Hurtbox, el padre es la Unidad (Unit.gd)
		var victim = area.get_parent()
		if victim.has_method("take_damage"):
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
