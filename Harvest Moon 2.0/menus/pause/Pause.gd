extends Control

var isOpen = false
var playBack

func _input(event):
	if event.is_action_pressed("pause") and isOpen == false:
		
		var Game = get_node("/root/Game")
		
		if Game.farmMusic.playing:
			playBack = Game.farmMusic.get_playback_position()
			Game.farmMusic.stop()
		elif Game.houseMusic.playing:
			playBack = Game.houseMusic.get_playback_position()
			Game.houseMusic.stop()
		
		get_tree().paused = true
		visible = true
		isOpen = true

func _on_Resume_pressed():
	get_tree().paused = false
	
	if get_parent().get_parent().get_parent().name == "Farm":
		get_node("/root/Game").farmMusic.play(playBack)
	else:
		get_node("/root/Game").houseMusic.play(playBack)
	visible = false
	isOpen = false

func _on_Controls_pressed():
	var controlsNode = get_parent().get_node("Controls")
	controlsNode.visible = true
	#controlsNode.paused = false
	visible = false

func _on_Quit_pressed():
	get_tree().change_scene("res://menus/main/MainMenu.tscn")
	get_tree().paused = false
	visible = false
	isOpen = false