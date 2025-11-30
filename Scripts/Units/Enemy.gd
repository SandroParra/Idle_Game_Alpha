extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var stats: EnemyStats

var target: CharacterBody2D = null

func _ready():
	if stats == null:
		push_warning("Enemy has no stats assigned")
		return
	else:
		stats = stats.duplicate()

	# Connect the AnimatedSprite2D signal properly
	animated_sprite.animation_finished.connect(_on_animation_finished)

	print("Enemy -> Name:", stats.name, " HP:", stats.health, " DMG:", stats.damage, " SPD:", stats.speed)

func _physics_process(_delta: float) -> void:
	var enemy = get_closest_enemy()
	if enemy == null:
		animated_sprite.play("Idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var enemy_distance = global_position.distance_to(enemy.global_position)
	var direction = global_position.direction_to(enemy.global_position)
	velocity = direction * stats.speed

	if enemy_distance <= 80:
		attack(enemy)
	else:
		animated_sprite.play("Walk")

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
	if animated_sprite.animation == "Attack_1" and target:
		print("Animation finished!")
		if target.has_method("take_damage"):
			print("found take damage!")
			target.take_damage(stats.damage)
	target = null
