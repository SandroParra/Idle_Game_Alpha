extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var targetMode = "closest"

var speed: float = 50.0
var closest_enemy: Node2D = null

func get_closest_enemy() -> Node2D:
	var shortest_distance = INF
	var enemies = get_tree().get_nodes_in_group("enemyGroup")

	for enemy in enemies:
		if enemy == null:
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy

	return closest_enemy

func _physics_process(_delta: float) -> void:
	var enemy = get_closest_enemy()

	if enemy == null:
		# No enemies yet → idle animation
		animated_sprite.play("Idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var enemy_distance = global_position.distance_to(enemy.global_position)
	var direction = position.direction_to(enemy.global_position)
	velocity = direction * speed

	if enemy_distance <= 50:
		animated_sprite.play("Attack_1")
	else:
		if speed > 50:
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Walk")

		if Input.is_action_just_pressed("ui_accept"):
			speed = 100

	move_and_slide()
