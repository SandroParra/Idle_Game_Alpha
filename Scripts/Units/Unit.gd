extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var anim = $AnimatedSprite2D # Usaremos esto en el paso de animación

var stats: CardData
var target: CharacterBody2D # La unidad enemiga

func initialize(data: CardData, _target: CharacterBody2D):
	stats = data
	target = _target
	if anim:
		anim.play("Walk")
		
func _physics_process(_delta):
	if not target: return
	# 1. Calcular dirección hacia el enemigo
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
		anim.play("Attack_1")
		return
