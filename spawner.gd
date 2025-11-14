extends Node2D

@onready var enemy = preload("res://Scenes/Enemy_Created/hyena.tscn")



func _on_timer_timeout() -> void:
	var ene = enemy.instantiate()
	ene.position = position
	
