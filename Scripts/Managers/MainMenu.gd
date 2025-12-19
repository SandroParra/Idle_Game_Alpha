extends Control

func _on_hero_manager_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/HeroManager/HeroManager.tscn")

func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/Arena/Arena.tscn")
