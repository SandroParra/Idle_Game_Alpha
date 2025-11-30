extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var anim = $AnimatedSprite2D # Usaremos esto en el paso de animación
var stats: CardData
var target: CharacterBody2D # La unidad enemiga

var is_dead = false


func initialize(data: CardData, _target: CharacterBody2D):
	stats = data.duplicate(true)
	target = _target
	if anim:
		anim.play("Walk")
		
func _physics_process(_delta):
	if not target: return
	# 1. Calcular dirección hacia el enemigo
	if not is_dead:
		var direction = global_position.direction_to(target.global_position)
		# 2. Moverse
		velocity = direction * stats.speed
		move_and_slide()
	
		# 3. Mirar hacia donde va (Flip horizontal)
		if anim:
			if direction.x < 0:
				anim.flip_h = true # Mirar izquierda
			elif direction.x > 0:
				anim.flip_h = false # Mirar derecha
	
		# 4. Verificar si llegamos (para atacar)
		if global_position.distance_to(target.global_position) <= stats.attack_range:
			velocity = Vector2.ZERO
			if not is_dead:
				anim.play("Attack_1")
			return


func take_damage(amount: int) -> void:
	var damage = max(amount - stats.defense, 1)
	stats.health -= damage
	print("Hero took ", damage, " and has ", stats.health, " health remaining")
	if stats.health <= 0:
		is_dead = true;
		die()
	
func die() -> void:
	print("Hero defeated!")
	if is_dead:
		anim.play("Death")
		anim.animation_finished.connect(_on_death_animation_finished, ConnectFlags.CONNECT_ONE_SHOT)
	
func _on_death_animation_finished():
	queue_free()
