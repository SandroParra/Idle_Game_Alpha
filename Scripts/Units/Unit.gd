extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var stats: CardData
var target: Node2D # La torre enemiga o unidad enemiga

func initialize(data: CardData, _target: Node2D):
	stats = data
	target = _target
	# Configurar velocidad del agente si es necesario
	nav_agent.max_speed = stats.speed

func _physics_process(_delta):
	if not target: return
	
	# 1. Definir destino
	nav_agent.target_position = target.global_position
	
	# 2. Verificar si llegamos (para atacar)
	if global_position.distance_to(target.global_position) <= stats.attack_range:
		velocity = Vector2.ZERO
		# Aquí llamarías a tu función de atacar
		return

	# 3. Moverse
	var current_pos = global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = current_pos.direction_to(next_path_pos)
	
	velocity = direction * stats.speed
	move_and_slide()
	
	# 4. Voltear el sprite según dirección (Izquierda/Derecha)
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
