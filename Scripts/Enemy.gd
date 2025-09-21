extends CharacterBody2D

class_name enemy

@export var default_facing_right: bool = true
const speed = 3000
var agroo_hyena: bool = false

var health = 80
var health_max = 80
var health_min = 0
var damage = 20

var dead: bool = false
var taking_damage: bool = false
var is_dealing_damage: bool = false

var dir: Vector2
var is_roaming: bool = true;

func _process(delta):
	move(delta)
	handle_animation()
	move_and_slide()
	
func move(delta):
	if !dead:
		if !agroo_hyena:
			velocity = dir * speed * delta
		is_roaming = true
	elif dead:
		print("dead")
			

func handle_animation():
	var anim_sprite = $AnimatedSprite2D
	if !dead and !taking_damage and !is_dealing_damage:
		
		if dir.x == 1 or dir.y == 1 or dir.y == -1:
			anim_sprite.animation = "Walk"
			anim_sprite.flip_h = true
		elif dir.x == -1:
			anim_sprite.animation = "Walk"
			anim_sprite.flip_h = false
		else:
			anim_sprite.animation = "Idle"
		anim_sprite.play()
	
	
	
func choose(array):
	array.shuffle()
	return array.front()


func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = choose([1.5, 2.0, 2.5])

	if !agroo_hyena:
		var possible_dirs = []
		
		if randi() % 4 == 0:
			possible_dirs.append(Vector2.ZERO)
		if !$RaycastRight.is_colliding():
			possible_dirs.append(Vector2.RIGHT)
		if !$RaycastLeft.is_colliding():
			possible_dirs.append(Vector2.LEFT)
		if !$RaycastUp.is_colliding():
			possible_dirs.append(Vector2.UP)
		if !$RaycastDown.is_colliding():
			possible_dirs.append(Vector2.DOWN)
			
		if possible_dirs.size() > 0:
			dir = choose(possible_dirs)
		else:
			dir = Vector2.ZERO
		print("decided for -> ", dir)
		velocity = Vector2.ZERO
