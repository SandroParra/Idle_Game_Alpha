extends CharacterBody2D

@onready var closest_enemy = null
@onready var animated_sprite = $AnimatedSprite2D
@onready var targetMode = "closest"

const SPEED = 50.0

func get_closest_enemy():
	var shortest_distance = INF # Initialize with a very large number

		# Get all nodes in the "enemies" group
	var enemies = get_tree().get_nodes_in_group("enemyGroup")

	for enemy in enemies:
			# Ensure the enemy node is valid and not freed
		if not is_instance_valid(enemy):
			continue
			# Calculate the distance to the current enemy
			# Use distance_squared_to() for performance if only comparing distances
		var distance = global_position.distance_to(enemy.global_position)
			# If this enemy is closer than the current shortest distance, update
		if distance < shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy
	return closest_enemy

func _physics_process(_delta: float) -> void:
	var enemy = get_closest_enemy()

	var direction = position.direction_to(enemy.global_position)
	velocity = direction * SPEED

	if direction.length() > 0.2:
		animated_sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("Attack")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	move_and_slide()
