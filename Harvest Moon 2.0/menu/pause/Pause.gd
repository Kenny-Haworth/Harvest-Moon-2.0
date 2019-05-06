extends Control

var isOpen = false

func _input(event):
	if event.is_action_pressed("pause") and isOpen == false:
		get_tree().paused = true
		visible = true
		isOpen = true

func _on_Resume_pressed():
	get_tree().paused = false
	visible = false
	isOpen = false

func _on_Controls_pressed():
	var controlsNode = get_node("/root/Game/Farm/Player/Camera2D/Controls")
	controlsNode.visible = true
	#controlsNode.paused = false
	visible = false

func _on_Quit_pressed():
	get_tree().change_scene("res://menu/main/MainMenu.tscn")
	get_tree().paused = false
	visible = false
	isOpen = false