extends Control

var menuMusic

func _ready():
	menuMusic = AudioStreamPlayer.new()
	self.add_child(menuMusic)
	menuMusic.stream = load("res://sound/Title Screen.wav")
	menuMusic.play()

func _on_Start_pressed():
	get_tree().change_scene("res://Game.tscn")

func _on_Controls_pressed():
	get_tree().change_scene("res://menus/controls/MainControls.tscn")

func _on_Options_pressed():
	get_tree().change_scene("res://menus/graphics/Graphics.tscn")