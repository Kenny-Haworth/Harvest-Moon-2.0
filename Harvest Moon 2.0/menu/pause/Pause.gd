extends Control

func _input(event):
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		visible = true

func _on_Resume_pressed():
	get_tree().paused = false
	visible = false

func _on_Controls_pressed():
	get_tree().change_scene("res://menu/controls/Controls.tscn")
	get_tree().paused = false
	visible = false

func _on_Quit_pressed():
	get_tree().change_scene("res://menu/main/MainMenu.tscn")
	get_tree().paused = false
	visible = false