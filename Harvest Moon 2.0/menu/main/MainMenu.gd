extends Control

func _on_Start_pressed():
	get_tree().change_scene("res://Game.tscn")

func _on_Controls_pressed():
	get_tree().change_scene("res://menu/controls/Controls.tscn")

func _on_Options_pressed():
	get_tree().change_scene("res://menu/graphics/Graphics.tscn")