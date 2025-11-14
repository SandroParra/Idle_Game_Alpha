extends CharacterBody2D

@export var move_speed: float = 55.0

@onready var hero = get_tree().get_first_node_in_group("heroGroup")
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void: 
	var direction = position.direction_to(hero.get_node("CollisionShape2D").global_position)
	velocity = direction * move_speed

	if direction.length() > 0.2:
		velocity = direction * move_speed
		animated_sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("Attack")
	move_and_slide()
