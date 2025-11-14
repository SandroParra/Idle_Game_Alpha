extends CharacterBody2D

@onready var closest_enemy = null
@onready var animated_sprite = $AnimatedSprite2D
@onready var targetMode = "closest"

var speed = 50.0

func get_closest_enemy():
	var shortest_distance = 99999 # Initialize with a very large number

		# Get all nodes in the "enemies" group
	var enemies = get_tree().get_nodes_in_group("enemyGroup")

	for enemy in enemies:
			# Calculate the distance to the current enemy
		var distance = global_position.distance_to(enemy.global_position)
			# If this enemy is closer than the current shortest distance, update
		if distance < shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy
	return closest_enemy

func _physics_process(_delta: float) -> void:
	var enemy = get_closest_enemy()
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
			
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	move_and_slide()
