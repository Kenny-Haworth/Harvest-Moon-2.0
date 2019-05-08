extends Panel

func _ready():
	get_tree().paused = true

func _on_Close_pressed():
	visible = false
	get_tree().paused = false
	var UI = get_node("/root/Game/Farm/Player/UI")
	UI.visible = true
	UI.get_node("CanvasLayer/Energy").visible = true
	get_parent().get_parent().get_parent().get_parent().farmMusic.play()